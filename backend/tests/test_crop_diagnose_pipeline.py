"""
Dedicated Pipeline Tests for AI Crop Disease Diagnosis (PyTorch + PostgreSQL + API).
"""
import pytest
import httpx
from app.main import app
from app.services.crop_ai_service import CropAIService
from PIL import Image
import io

@pytest.fixture
def test_leaf_bytes():
    # Create a 224x224 RGB test leaf image in memory
    img = Image.new('RGB', (224, 224), color=(34, 139, 34))
    buf = io.BytesIO()
    img.save(buf, format='JPEG')
    return buf.getvalue()

@pytest.mark.asyncio
async def test_crop_ai_service_singleton():
    service = CropAIService.get_instance()
    assert service is not None
    assert service._model is not None
    assert len(service._class_names) == 21

@pytest.mark.asyncio
async def test_pytorch_inference_execution(test_leaf_bytes):
    service = CropAIService.get_instance()
    res = service.run_inference(test_leaf_bytes, crop_hint='tomato')
    assert 'predicted_class' in res
    assert 'confidence' in res
    assert 'crop' in res
    assert res['crop'] == 'Tomato'
    assert res['predicted_class'].startswith('Tomato___')

@pytest.mark.asyncio
async def test_postgresql_disease_profile_query():
    service = CropAIService.get_instance()
    profile = await service.get_disease_profile_from_db(None, 'Tomato___Septoria_leaf_spot')
    assert profile is not None
    assert profile['disease_name'] == 'Tomato Septoria Leaf Spot'
    assert len(profile['symptoms']) > 0
    assert 'chemical' in profile['treatments']
    assert len(profile['prevention_steps']) > 0
    assert len(profile['sources']) > 0

@pytest.mark.asyncio
async def test_api_diagnose_multipart(test_leaf_bytes):
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url='http://test') as client:
        files = {'file': ('test_leaf.jpg', test_leaf_bytes, 'image/jpeg')}
        data = {'crop_hint': 'apple', 'gps_lat': '31.1048', 'gps_lon': '77.1734', 'district_code': 'HP_SHI'}
        resp = await client.post('/api/diagnose', files=files, data=data)
        assert resp.status_code == 200
        json_data = resp.json()
        assert json_data['success'] is True
        assert json_data['crop'] == 'Apple'
        assert 'disease_name' in json_data
        assert 'disease_profile' in json_data
        assert json_data['disease_profile'] is not None

@pytest.mark.asyncio
async def test_api_v1_diagnose_alias(test_leaf_bytes):
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url='http://test') as client:
        files = {'file': ('test_leaf.jpg', test_leaf_bytes, 'image/jpeg')}
        data = {'crop_hint': 'potato'}
        resp = await client.post('/api/v1/diagnose', files=files, data=data)
        assert resp.status_code == 200
        json_data = resp.json()
        assert json_data['success'] is True
        assert json_data['crop'] == 'Potato'
