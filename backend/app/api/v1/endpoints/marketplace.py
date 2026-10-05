"""
Marketplace Endpoints — Products, Real Order Checkout, Tamper-proof Verification, and Tracking.
"""
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional, List
from app.db.session import get_db
from app.api.deps import get_optional_farmer
from app.models.farmer import Farmer
from app.schemas.marketplace import (
    ProductSchema, ProductListResponse, OrderCreateRequest, OrderResponse,
    CouponValidateRequest, CouponValidateResponse,
    VerifyDeliveryOtpRequest, VerifyDeliveryOtpResponse
)
from app.services.marketplace_service import MarketplaceService

router = APIRouter(prefix="/marketplace", tags=["Krishi Marketplace"])


@router.get("/products", response_model=ProductListResponse)
async def list_marketplace_products(
    q: Optional[str] = Query(None, description="Search keyword, crop name, or disease"),
    category: Optional[str] = Query(None, description="Category filter (fungicides, fertilizers, etc.)"),
    brand: Optional[str] = Query(None, description="Brand filter (Syngenta, UPL, etc.)"),
    min_price: Optional[float] = Query(None, ge=0),
    max_price: Optional[float] = Query(None, ge=0),
    min_rating: Optional[float] = Query(None, ge=0, le=5),
    assured_only: Optional[bool] = Query(False),
    sort_by: Optional[str] = Query("popularity", description="Sort by: popularity, price_low_to_high, price_high_to_low, rating, discount"),
):
    """
    Search and filter authentic agricultural curing products, bio-fertilizers, and equipment.
    """
    products = MarketplaceService.search_products(
        query=q,
        category=category,
        brand=brand,
        min_price=min_price,
        max_price=max_price,
        min_rating=min_rating,
        assured_only=assured_only,
        sort_by=sort_by,
    )
    return ProductListResponse(total=len(products), products=products)


@router.get("/products/{product_id}", response_model=ProductSchema)
async def get_product_details(product_id: str):
    """
    Fetch comprehensive product specifications, dosage rates, and disease targets.
    """
    prod = MarketplaceService.get_product_by_id(product_id)
    if not prod:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product with ID '{product_id}' not found in Krishi catalog",
        )
    return prod


@router.post("/coupons/validate", response_model=CouponValidateResponse)
async def validate_farmer_coupon(req: CouponValidateRequest):
    """
    Validate promotional and government-subsidy coupon codes against order total.
    """
    return MarketplaceService.validate_coupon(req.code, req.order_amount)


@router.post("/orders", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
async def place_marketplace_order(
    req: OrderCreateRequest,
    db: AsyncSession = Depends(get_db),
    farmer: Optional[Farmer] = Depends(get_optional_farmer),
):
    """
    Execute real marketplace order checkout with server-side price protection,
    delivery OTP creation, and tamper-proof HMAC verification.
    """
    farmer_id = str(farmer.id) if farmer else None
    order = await MarketplaceService.place_order(db=db, req=req, farmer_id=farmer_id)
    return order


@router.get("/orders/{order_id}", response_model=OrderResponse)
async def get_order_tracking(
    order_id: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Retrieve live dispatch timeline and delivery details for an order.
    """
    order = await MarketplaceService.get_order_by_id(db=db, order_id=order_id)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Order '{order_id}' not found in Krishi records",
        )
    return order


@router.post("/orders/{order_id}/cancel")
async def cancel_order(
    order_id: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Cancel an active order before dispatch and trigger automated refund.
    """
    success = await MarketplaceService.cancel_order(db=db, order_id=order_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Order cannot be cancelled. It may already be dispatched, delivered, or does not exist.",
        )
    return {"success": True, "message": f"Order {order_id} has been cancelled and refund initiated."}


@router.post("/orders/verify-otp", response_model=VerifyDeliveryOtpResponse)
async def verify_delivery_otp(
    req: VerifyDeliveryOtpRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Verify the 4-digit OTP upon doorstep delivery to the farm.
    """
    return await MarketplaceService.verify_delivery_otp(db=db, order_id=req.order_id, otp=req.delivery_otp)
