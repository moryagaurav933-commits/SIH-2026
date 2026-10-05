"""
Pydantic schemas for Krishi Marketplace — Validates order checkouts, coupons, and secure OTP verification.
"""
from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List
from datetime import datetime


class ProductSchema(BaseModel):
    id: str
    title: str
    scientific_name: str
    brand: str
    category: str
    pack_size: str
    price: float
    mrp: float
    discount_percent: float
    image_asset: str
    is_assured: bool = True
    offer_tag: Optional[str] = None
    rating: float = 4.8
    rating_count: int = 120
    suitable_crops: List[str] = []
    target_diseases: List[str] = []
    dosage: Optional[str] = None
    application_method: Optional[str] = None
    safety_wait_period: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class ProductListResponse(BaseModel):
    success: bool = True
    total: int
    products: List[ProductSchema]


class OrderItemSchema(BaseModel):
    product_id: str
    title: str
    brand: str
    pack_size: str
    price: float
    quantity: int = Field(..., ge=1)
    image_asset: Optional[str] = None


class OrderCreateRequest(BaseModel):
    items: List[OrderItemSchema] = Field(..., min_length=1)
    recipient_name: str = Field(..., min_length=2, max_length=100)
    recipient_phone: str = Field(..., min_length=10, max_length=15)
    delivery_address: str = Field(..., min_length=5, max_length=500)
    delivery_pincode: str = Field(..., min_length=6, max_length=6)
    payment_method: str = Field(default="KCC Digital Card")
    payment_status: str = Field(default="PAID")
    coupon_code: Optional[str] = None
    instructions: Optional[str] = None


class OrderResponse(BaseModel):
    order_id: str
    recipient_name: str
    recipient_phone_masked: str
    delivery_address: str
    delivery_pincode: str
    payment_method: str
    payment_status: str
    subtotal: float
    delivery_fee: float
    marketplace_fee: float
    subsidy: float
    coupon_discount: float
    coupon_code: Optional[str] = None
    total_paid: float
    diamonds_earned: int
    status: str
    delivery_otp: str
    tracking_number: str
    tamper_checksum: str
    items: List[OrderItemSchema]
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class OrderListResponse(BaseModel):
    success: bool = True
    orders: List[OrderResponse]


class CouponValidateRequest(BaseModel):
    code: str
    order_amount: float = Field(..., ge=0.0)


class CouponValidateResponse(BaseModel):
    valid: bool
    coupon_code: str
    discount_amount: float
    message: str


class VerifyDeliveryOtpRequest(BaseModel):
    order_id: str
    delivery_otp: str = Field(..., min_length=4, max_length=6)


class VerifyDeliveryOtpResponse(BaseModel):
    success: bool
    order_id: str
    status: str
    message: str
