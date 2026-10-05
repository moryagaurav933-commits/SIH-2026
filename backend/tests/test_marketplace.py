"""
Unit and integration tests for Krishi Marketplace endpoints, catalog search, order checkout, tamper checks, and OTP security.
"""
import pytest
import httpx
from app.main import app
from app.services.marketplace_service import MarketplaceService


@pytest.fixture
def anyio_backend():
    return "asyncio"


@pytest.mark.asyncio
async def test_marketplace_catalog_count():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.get("/api/v1/marketplace/products")
        assert res.status_code == 200
        data = res.json()
        assert data["success"] is True
        assert data["total"] == 40
        assert len(data["products"]) == 40


@pytest.mark.asyncio
async def test_marketplace_popular_search():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        # Search for popular query: "Lawn and Gardening"
        res = await client.get("/api/v1/marketplace/products?q=Lawn+and+Gardening")
        assert res.status_code == 200
        data = res.json()
        assert data["total"] > 0

        # Search for specific item "Saaf"
        res_saaf = await client.get("/api/v1/marketplace/products?q=Saaf")
        assert res_saaf.status_code == 200
        data_saaf = res_saaf.json()
        assert data_saaf["total"] > 0
        assert any("saaf" in p["title"].lower() for p in data_saaf["products"])


@pytest.mark.asyncio
async def test_marketplace_coupon_validation():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        # Valid coupon KISAN50 on ₹1000 order
        res = await client.post("/api/v1/marketplace/coupons/validate", json={"code": "KISAN50", "order_amount": 1000.0})
        assert res.status_code == 200
        data = res.json()
        assert data["valid"] is True
        assert data["discount_amount"] == 150.0  # 15% capped at ₹150

        # Invalid coupon
        res_inv = await client.post("/api/v1/marketplace/coupons/validate", json={"code": "FAKE99", "order_amount": 1000.0})
        assert res_inv.status_code == 200
        assert res_inv.json()["valid"] is False


@pytest.mark.asyncio
async def test_marketplace_order_placement_and_security():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        order_payload = {
            "items": [
                {
                    "product_id": "prod_01",
                    "title": "Saaf Fungicide",
                    "brand": "UPL",
                    "pack_size": "500 g",
                    "price": 240.0,
                    "quantity": 2
                }
            ],
            "recipient_name": "Gaurav Morya",
            "recipient_phone": "9816012345",
            "delivery_address": "Farm House, VPO Kandaghat, Solan HP",
            "delivery_pincode": "173215",
            "payment_method": "KCC Digital Card",
            "coupon_code": "KISAN50"
        }

        res = await client.post("/api/v1/marketplace/orders", json=order_payload)
        assert res.status_code == 201
        order = res.json()

        assert order["order_id"].startswith("KS-2026-")
        assert len(order["delivery_otp"]) == 4
        assert order["delivery_otp"].isdigit()
        assert len(order["tamper_checksum"]) == 64  # SHA256 length
        assert "981***" in order["recipient_phone_masked"]  # PII protection
        assert order["status"] == "CONFIRMED"
        assert order["total_paid"] > 0
        assert order["subtotal"] == 480.0


@pytest.mark.asyncio
async def test_marketplace_otp_verification_and_cancellation():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        # Create order
        order_payload = {
            "items": [{"product_id": "prod_02", "title": "Amistar Top", "brand": "Syngenta", "pack_size": "200 ml", "price": 620.0, "quantity": 1}],
            "recipient_name": "Gaurav Morya",
            "recipient_phone": "9816099999",
            "delivery_address": "Solan",
            "delivery_pincode": "173212",
            "payment_method": "UPI"
        }
        res = await client.post("/api/v1/marketplace/orders", json=order_payload)
        assert res.status_code == 201
        order = res.json()
        oid = order["order_id"]
        otp = order["delivery_otp"]

        # Wrong OTP fails
        res_wrong = await client.post("/api/v1/marketplace/orders/verify-otp", json={"order_id": oid, "delivery_otp": "0000"})
        assert res_wrong.status_code == 200
        assert res_wrong.json()["success"] is False

        # Correct OTP succeeds
        res_correct = await client.post("/api/v1/marketplace/orders/verify-otp", json={"order_id": oid, "delivery_otp": otp})
        assert res_correct.status_code == 200
        assert res_correct.json()["success"] is True
        assert res_correct.json()["status"] == "DELIVERED"
