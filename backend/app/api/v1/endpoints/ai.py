"""
Krishi-Saarthi AI & LLM Endpoints
Provides chat, multimodal leaf diagnosis, API key management, and agricultural knowledge.
"""
from fastapi import APIRouter, HTTPException, Header, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
import hashlib

from app.db.session import get_db
from app.models.farmer import Farmer
from app.models.diagnosis import CropDiagnosis
from app.models.disease_telemetry import DiseaseTelemetry
from app.services.ai_service import AIService, AGRICULTURAL_KNOWLEDGE_BASE, SCHEMES_KNOWLEDGE
from app.services.rate_limiter import gemini_limiter, mask_key

router = APIRouter(prefix="/ai", tags=["AI & LLM Agronomist"])


class ChatRequest(BaseModel):
    message: str = Field(..., description="Farmer query or agronomic question")
    language: str = Field("hi", description="Language code ('hi', 'en', 'mr', 'pa')")
    history: Optional[List[Dict[str, str]]] = Field(None, description="Prior conversation history")
    api_key: Optional[str] = Field(None, description="Optional Google Gemini API Key override")


class DiagnoseRequest(BaseModel):
    image_base64: str = Field(..., description="Base64 encoded leaf photograph")
    crop_hint: Optional[str] = Field(None, description="Crop name (wheat, rice, cotton, etc.)")
    language: str = Field("hi", description="Language for diagnosis report")
    api_key: Optional[str] = Field(None, description="Optional Google Gemini API Key override")
    gps_lat: Optional[float] = Field(26.8467, description="GPS latitude (default: Lucknow)")
    gps_lon: Optional[float] = Field(80.9462, description="GPS longitude (default: Lucknow)")
    district_code: Optional[str] = Field("UP_LKO", description="District code")


class ConfigureKeyRequest(BaseModel):
    api_key: str = Field(..., description="Google Gemini API key")


@router.post("/chat")
async def chat_agronomist(req: ChatRequest, x_api_key: Optional[str] = Header(None)):
    """Conversational agronomist: answers farming questions via Gemini LLM or ICAR RAG knowledge."""
    effective_key = req.api_key or x_api_key
    res = await AIService.chat_with_agronomist(
        message=req.message,
        language=req.language,
        history=req.history,
        override_key=effective_key
    )
    return res


@router.post("/diagnose")
async def diagnose_leaf(
    req: DiagnoseRequest,
    x_api_key: Optional[str] = Header(None),
    db: AsyncSession = Depends(get_db),
):
    """Multimodal vision diagnosis: inspects leaf image for pathogens, cures, and spot spray dosages."""
    effective_key = req.api_key or x_api_key
    res = await AIService.diagnose_leaf_image(
        image_base64=req.image_base64,
        crop_hint=req.crop_hint,
        language=req.language,
        override_key=effective_key
    )

    # Persist live diagnosis to database and disease telemetry for Kriging vector maps
    try:
        diag_data = res.get("diagnosis") if isinstance(res.get("diagnosis"), dict) else res
        disease_en = diag_data.get("disease_name_en") or diag_data.get("disease_name") or "Leaf Spot"
        disease_hi = diag_data.get("disease_name_hi") or disease_en
        confidence = float(diag_data.get("confidence") or 0.88)
        sev_pct = float(diag_data.get("severity_percent") or 30.0)
        sev_str = "critical" if sev_pct > 60 else ("high" if sev_pct > 35 else ("medium" if sev_pct > 15 else "low"))
        crop = diag_data.get("crop") or req.crop_hint or "wheat"
        treat_rec = diag_data.get("chemical_cure") or diag_data.get("treatment_recommendation") or ""
        treat_hi = diag_data.get("organic_cure") or treat_rec

        # Link to active or default demo farmer
        result = await db.execute(select(Farmer).limit(1))
        farmer = result.scalar_one_or_none()
        if not farmer:
            farmer = Farmer(
                name="Rameshwar Singh",
                phone="9876543210",
                district_code=req.district_code or "UP_LKO",
                state="Uttar Pradesh",
                aadhaar_hash="sha256_mock_farmer_aadhaar",
                preferred_language="hi",
            )
            db.add(farmer)
            await db.flush()

        img_hash = hashlib.sha256(req.image_base64[:200].encode()).hexdigest()
        diagnosis = CropDiagnosis(
            farmer_id=farmer.id,
            image_hash=img_hash,
            disease_name=disease_en,
            disease_name_hi=disease_hi,
            confidence=confidence,
            severity=sev_str,
            crop_type=crop,
            treatment_recommendation=treat_rec,
            treatment_recommendation_hi=treat_hi,
            gps_lat=req.gps_lat,
            gps_lon=req.gps_lon,
            district_code=req.district_code or farmer.district_code,
            model_version=res.get("source") or "gemini-2.5-flash",
            sync_status="synced",
        )
        db.add(diagnosis)

        if req.gps_lat and req.gps_lon and "healthy" not in disease_en.lower():
            telemetry = DiseaseTelemetry(
                disease_name=disease_en,
                gps_lat=req.gps_lat,
                gps_lon=req.gps_lon,
                district_code=req.district_code or farmer.district_code,
                confidence=confidence,
                severity=sev_str,
                crop_type=crop,
                source_diagnosis_id=diagnosis.id,
            )
            db.add(telemetry)

        await db.flush()
        res["database_id"] = str(diagnosis.id)
        res["persisted_to_db"] = True
    except Exception as e:
        # Non-blocking DB logging fallback
        res["database_sync_warning"] = str(e)

    return res


from app.services.rate_limiter import gemini_limiter, mask_key

@router.get("/key-status")
async def get_key_status(x_api_key: Optional[str] = Header(None)):
    """Check if Gemini API Key is configured and ready."""
    key = AIService.get_api_key(x_api_key)
    if key and len(key) > 8:
        masked = mask_key(key)
        limiter_info = gemini_limiter.get_status()
        return {
            "configured": True,
            "masked_key": masked,
            "active_model": "gemini-2.5-flash",
            "capabilities": ["multimodal_vision", "voice_copilot", "icar_rag", "realtime_treatment"],
            "status": "ready",
            "quota": limiter_info
        }
    return {
        "configured": False,
        "masked_key": None,
        "active_model": "icar-offline-edge",
        "capabilities": ["icar_offline_rag", "quantized_cv", "rule_based_dosage"],
        "status": "offline_fallback_active"
    }


@router.post("/configure-key")
async def configure_api_key(req: ConfigureKeyRequest):
    """Runtime configuration of Gemini API Key for demo and local deployments."""
    cleaned = req.api_key.strip()
    if len(cleaned) < 10:
        raise HTTPException(status_code=400, detail="Invalid API Key format")
    AIService.set_runtime_api_key(cleaned)
    return {
        "success": True,
        "message": "Google Gemini API Key configured successfully",
        "masked_key": mask_key(cleaned)
    }


@router.get("/knowledge")
async def get_agricultural_knowledge():
    """Retrieve full ICAR package of practices and government schemes reference data."""
    return {
        "crops": AGRICULTURAL_KNOWLEDGE_BASE,
        "schemes": SCHEMES_KNOWLEDGE,
        "source": "ICAR-CIBRC Agronomic Standards 2026"
    }


@router.get("/quota-status")
async def get_quota_status():
    """Returns Gemini API sliding window quota (15 requests/hour free-tier protection)."""
    return gemini_limiter.get_status()

