"""
Diagnosis endpoints - Crop disease detection results.
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import List, Optional
import uuid
import hashlib
from uuid import UUID
from app.db.session import get_db
from app.api.deps import get_current_farmer, get_optional_farmer
from app.models.farmer import Farmer
from app.models.diagnosis import CropDiagnosis
from app.models.disease_telemetry import DiseaseTelemetry
from app.schemas.schemas import DiagnosisSubmit, DiagnosisResponse

router = APIRouter(prefix="/diagnoses", tags=["Crop Diagnosis"])


@router.post("/", response_model=DiagnosisResponse, status_code=status.HTTP_201_CREATED)
async def submit_diagnosis(
    data: DiagnosisSubmit,
    farmer: Optional[Farmer] = Depends(get_optional_farmer),
    db: AsyncSession = Depends(get_db),
):
    """Submit a new crop diagnosis result from on-device CV model or frontend."""
    if farmer is None:
        result = await db.execute(select(Farmer).limit(1))
        farmer = result.scalar_one_or_none()
        if not farmer:
            farmer = Farmer(
                id=uuid.uuid4(),
                full_name="Rameshwar Singh",
                phone_hash=hashlib.sha256(b"+919876543210").hexdigest(),
                aadhaar_hash=hashlib.sha256(b"123456789012").hexdigest(),
                district_code=data.district_code or "UP_LKO",
                state_code="UP",
                preferred_language="hi",
                is_active=True,
            )
            db.add(farmer)
            await db.flush()

    diagnosis = CropDiagnosis(
        farmer_id=farmer.id,
        plot_id=data.plot_id,
        image_hash=data.image_hash,
        disease_name=data.disease_name,
        disease_name_hi=data.disease_name_hi,
        confidence=data.confidence,
        severity=data.severity,
        crop_type=data.crop_type,
        treatment_recommendation=data.treatment_recommendation,
        treatment_recommendation_hi=data.treatment_recommendation_hi,
        gps_lat=data.gps_lat,
        gps_lon=data.gps_lon,
        district_code=data.district_code or farmer.district_code,
        device_signature=data.device_signature,
        model_version=data.model_version,
        sync_status="synced",
    )
    db.add(diagnosis)

    # Also add to disease telemetry for kriging
    if data.gps_lat and data.gps_lon and data.disease_name.lower() != "healthy":
        telemetry = DiseaseTelemetry(
            disease_name=data.disease_name,
            gps_lat=data.gps_lat,
            gps_lon=data.gps_lon,
            district_code=data.district_code or farmer.district_code,
            confidence=data.confidence,
            severity=data.severity,
            crop_type=data.crop_type,
            source_diagnosis_id=diagnosis.id,
        )
        db.add(telemetry)

    await db.flush()
    return DiagnosisResponse.model_validate(diagnosis)


@router.get("/", response_model=List[DiagnosisResponse])
async def get_diagnoses(
    farmer: Optional[Farmer] = Depends(get_optional_farmer),
    db: AsyncSession = Depends(get_db),
    limit: int = Query(default=50, le=200),
    offset: int = Query(default=0, ge=0),
    crop_type: Optional[str] = None,
):
    """Get farmer's diagnosis history, or recent community diagnoses if unauthenticated."""
    query = select(CropDiagnosis)
    if farmer:
        query = query.where(CropDiagnosis.farmer_id == farmer.id)
    if crop_type:
        query = query.where(CropDiagnosis.crop_type == crop_type)
    query = query.order_by(CropDiagnosis.diagnosed_at.desc()).limit(limit).offset(offset)

    result = await db.execute(query)
    return [DiagnosisResponse.model_validate(d) for d in result.scalars().all()]


@router.get("/stats")
async def get_diagnosis_stats(
    db: AsyncSession = Depends(get_db),
    district_code: Optional[str] = None,
):
    """Get aggregate diagnosis statistics for admin dashboard."""
    query = select(
        CropDiagnosis.disease_name,
        func.count(CropDiagnosis.id).label("count"),
        func.avg(CropDiagnosis.confidence).label("avg_confidence"),
    ).group_by(CropDiagnosis.disease_name)

    if district_code:
        query = query.where(CropDiagnosis.district_code == district_code)

    result = await db.execute(query)
    rows = result.all()

    return {
        "disease_stats": [
            {"disease_name": row[0], "count": row[1], "avg_confidence": round(float(row[2] or 0), 3)}
            for row in rows
        ]
    }


import base64
import hashlib
from fastapi import File, UploadFile, Form, Request
from app.services.crop_ai_service import CropAIService

async def process_leaf_diagnosis(
    request: Request,
    file: Optional[UploadFile] = None,
    image: Optional[UploadFile] = None,
    image_base64: Optional[str] = None,
    crop_type: Optional[str] = None,
    crop_hint: Optional[str] = None,
    gps_lat: Optional[float] = None,
    gps_lon: Optional[float] = None,
    district_code: Optional[str] = None,
    farmer: Optional[Farmer] = None,
    db: AsyncSession = None,
):
    content_type = request.headers.get("content-type", "")
    req_crop = crop_type or crop_hint
    req_lat = gps_lat
    req_lon = gps_lon
    req_district = district_code or "UP_LKO"
    img_bytes = None

    if "application/json" in content_type:
        try:
            body = await request.json()
            if isinstance(body, dict):
                b64 = body.get("image_base64") or body.get("image")
                if b64:
                    if "," in b64:
                        b64 = b64.split(",", 1)[1]
                    img_bytes = base64.b64decode(b64)
                req_crop = req_crop or body.get("crop_type") or body.get("crop_hint") or body.get("crop")
                req_lat = req_lat or body.get("gps_lat")
                req_lon = req_lon or body.get("gps_lon")
                req_district = body.get("district_code") or req_district
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid JSON payload: {e}")
    else:
        upload = file or image
        if upload and upload.filename:
            img_bytes = await upload.read()
        elif image_base64:
            b64 = image_base64
            if "," in b64:
                b64 = b64.split(",", 1)[1]
            img_bytes = base64.b64decode(b64)

    if not img_bytes:
        raise HTTPException(
            status_code=400,
            detail="No image provided. Upload an image file ('file' or 'image') or provide 'image_base64'."
        )

    # 1. AI PyTorch Inference
    service = CropAIService.get_instance()
    try:
        inference_result = service.run_inference(img_bytes, crop_hint=req_crop)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI Inference failed: {e}")

    ml_class = inference_result["predicted_class"]

    # 2. Database Profile Lookup
    disease_profile = await service.get_disease_profile_from_db(db, ml_class)

    # 3. Persistence into crop_diagnoses & telemetry
    diagnosis_record_id = None
    try:
        if farmer is None:
            res = await db.execute(select(Farmer).limit(1))
            farmer = res.scalar_one_or_none()
            if not farmer:
                phone_h = hashlib.sha256(b"+919876543210").hexdigest()
                aadhaar_h = hashlib.sha256(b"123456789012").hexdigest()
                farmer = Farmer(
                    id=uuid.uuid4(),
                    full_name="Rameshwar Singh",
                    phone_hash=phone_h,
                    aadhaar_hash=aadhaar_h,
                    district_code=req_district or "UP_LKO",
                    state_code="UP",
                    preferred_language="hi",
                    is_active=True,
                )
                db.add(farmer)
                await db.flush()

        img_hash = hashlib.sha256(img_bytes).hexdigest()
        
        # Primary treatment string
        treatments_obj = (disease_profile or {}).get("treatments", {})
        chem_cures = treatments_obj.get("chemical", [])
        org_cures = treatments_obj.get("cultural", []) + treatments_obj.get("biological", [])
        treat_rec = "; ".join(chem_cures) if chem_cures else (inference_result.get("kb_immediate_action") or "")
        treat_hi = "; ".join(org_cures) if org_cures else treat_rec

        sev = (disease_profile or {}).get("severity", "medium")
        if "critical" in sev.lower():
            sev_str = "critical"
        elif "high" in sev.lower():
            sev_str = "high"
        elif "low" in sev.lower():
            sev_str = "low"
        else:
            sev_str = "medium" if not inference_result["is_healthy"] else "healthy"

        diag = CropDiagnosis(
            farmer_id=farmer.id,
            image_hash=img_hash,
            disease_name=(disease_profile or {}).get("disease_name") or ml_class,
            disease_name_hi=inference_result["disease_name_hi"],
            confidence=inference_result["confidence"],
            severity=sev_str,
            crop_type=inference_result["crop"].lower(),
            treatment_recommendation=treat_rec,
            treatment_recommendation_hi=treat_hi,
            gps_lat=req_lat or 26.8467,
            gps_lon=req_lon or 80.9462,
            district_code=req_district,
            model_version=inference_result["model_engine"],
            sync_status="synced",
        )
        db.add(diag)
        await db.flush()
        diagnosis_record_id = str(diag.id)

        if req_lat and req_lon and not inference_result["is_healthy"]:
            telemetry = DiseaseTelemetry(
                disease_name=diag.disease_name,
                gps_lat=req_lat,
                gps_lon=req_lon,
                district_code=req_district,
                confidence=inference_result["confidence"],
                severity=sev_str,
                crop_type=diag.crop_type,
                source_diagnosis_id=diag.id,
            )
            db.add(telemetry)
            await db.flush()
    except Exception as e:
        # Non-blocking db persistence warning
        pass

    return {
        "success": True,
        "status": "success",
        "predicted_class": ml_class,
        "disease_name": (disease_profile or {}).get("disease_name") or ml_class,
        "disease_name_hi": inference_result["disease_name_hi"],
        "crop": inference_result["crop"],
        "confidence": inference_result["confidence"],
        "is_healthy": inference_result["is_healthy"],
        "model_version": inference_result["model_engine"],
        "diagnosis_id": diagnosis_record_id,
        "ml_prediction": inference_result,
        "disease_profile": disease_profile,
        "kb_info": {
            "immediate_action": inference_result.get("kb_immediate_action"),
            "faq": inference_result.get("kb_faq", [])
        }
    }


@router.post("/diagnose")
async def diagnose_leaf(
    request: Request,
    file: Optional[UploadFile] = File(None),
    image: Optional[UploadFile] = File(None),
    image_base64: Optional[str] = Form(None),
    crop_type: Optional[str] = Form(None),
    crop_hint: Optional[str] = Form(None),
    gps_lat: Optional[float] = Form(None),
    gps_lon: Optional[float] = Form(None),
    district_code: Optional[str] = Form(None),
    farmer: Optional[Farmer] = Depends(get_optional_farmer),
    db: AsyncSession = Depends(get_db),
):
    """Multimodal leaf diagnosis using PyTorch model & PostgreSQL complete disease profile."""
    return await process_leaf_diagnosis(
        request=request,
        file=file,
        image=image,
        image_base64=image_base64,
        crop_type=crop_type,
        crop_hint=crop_hint,
        gps_lat=gps_lat,
        gps_lon=gps_lon,
        district_code=district_code,
        farmer=farmer,
        db=db,
    )
