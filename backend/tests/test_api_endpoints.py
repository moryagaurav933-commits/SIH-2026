"""
Automated Integration Tests for Krishi-Saarthi FastAPI backend.
Tests all endpoints covering the 13 features.
"""
import pytest
import httpx
from app.main import app

@pytest.fixture
def anyio_backend():
    return "asyncio"

@pytest.mark.asyncio
async def test_health_check():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] in ["healthy", "degraded"]
        assert "Krishi-Saarthi" in data["app"]

@pytest.mark.asyncio
async def test_root_endpoint():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["docs"] == "/docs"

@pytest.mark.asyncio
async def test_docs_endpoint_theme():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/docs")
        assert response.status_code == 200
        assert "--primary-green: #2E7D32" in response.text
        assert "Krishi-Saarthi" in response.text

@pytest.mark.asyncio
async def test_weather_forecast():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/weather/forecast?district_code=UP_LKO")
        assert response.status_code == 200
        data = response.json()
        assert data["district_code"] == "UP_LKO"
@pytest.mark.asyncio
async def test_mandi_prices():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/mandi/prices")
        assert response.status_code == 200
        items = response.json()
        assert isinstance(items, list)
        assert len(items) > 0
        first = items[0]
        assert "crop_name" in first
        assert "price_per_quintal" in first



@pytest.mark.asyncio
async def test_kriging_risk_surface():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/kriging/risk-surface?district_code=UP_LKO")
        assert response.status_code == 200
        data = response.json()
        assert "features" in data
        assert "metadata" in data
        assert data["metadata"]["grid_size"] > 0

@pytest.mark.asyncio
async def test_dashboard_stats():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/dashboard/stats")
        assert response.status_code == 200
        data = response.json()
        assert data["total_farmers"] >= 1
        assert data["total_diagnoses"] >= 1

@pytest.mark.asyncio
async def test_disease_heatmap():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/dashboard/disease-heatmap")
        assert response.status_code == 200
        data = response.json()
        assert "heatmap_data" in data
        assert len(data["heatmap_data"]) > 0

@pytest.mark.asyncio
async def test_ai_key_status():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/ai/key-status")
        assert response.status_code == 200
        data = response.json()
        assert "configured" in data
        assert "capabilities" in data

@pytest.mark.asyncio
async def test_ai_chat_offline_and_knowledge():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        payload = {"message": "गेहूं में पीला रतुआ का इलाज क्या है?", "language": "hi"}
        response = await client.post("/api/v1/ai/chat", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "पीला रतुआ" in data["reply"] or "प्रोपिकोनाज़ोल" in data["reply"]


@pytest.mark.asyncio
async def test_mandi_endpoints():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Test Mandis list with distance calculation
        resp_mandis = await client.get("/api/v1/mandi/mandis?lat=28.71&lon=77.17")
        assert resp_mandis.status_code == 200
        mandis = resp_mandis.json()
        assert len(mandis) > 0
        assert mandis[0]["distance_km"] is not None
        assert "id" in mandis[0]

        # 2. Test Closest Mandi
        resp_closest = await client.get("/api/v1/mandi/closest?lat=28.71&lon=77.17")
        assert resp_closest.status_code == 200
        closest = resp_closest.json()
        assert "id" in closest
        assert "name" in closest

        # 3. Test Mandi Prices with arrival quantity and modal price
        resp_prices = await client.get("/api/v1/mandi/prices?mandi_id=DL_AZADPUR&crop_name=Wheat")
        assert resp_prices.status_code == 200
        prices = resp_prices.json()
        assert len(prices) > 0
        assert prices[0]["crop_name"] == "Wheat"
        assert prices[0]["modal_price"] is not None
        assert prices[0]["arrival_quantity_quintal"] is not None


