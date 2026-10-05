"""
Krishi Marketplace database models — Products, Verified Orders, and Farmer Subsidies.
Ensures privacy-preserving storage, tamper-proof order verification, and secure checkouts.
"""
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Text, Boolean, ForeignKey, Float, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.db.base import Base


class MarketplaceProduct(Base):
    __tablename__ = "marketplace_products"

    id = Column(String(50), primary_key=True)  # prod_01 ... prod_40
    title = Column(String(255), nullable=False, index=True)
    scientific_name = Column(String(255), nullable=False, index=True)
    brand = Column(String(100), nullable=False, index=True)
    category = Column(String(50), nullable=False, index=True)
    pack_size = Column(String(50), nullable=False)
    price = Column(Float, nullable=False)
    mrp = Column(Float, nullable=False)
    discount_percent = Column(Float, nullable=False, default=0.0)
    image_asset = Column(String(255), nullable=False)
    is_assured = Column(Boolean, default=True, nullable=False)
    offer_tag = Column(String(100), nullable=True)
    rating = Column(Float, default=4.8)
    rating_count = Column(Integer, default=120)
    suitable_crops = Column(Text, nullable=True)     # Comma-separated or JSON string
    target_diseases = Column(Text, nullable=True)    # Comma-separated or JSON string
    dosage = Column(String(255), nullable=True)
    application_method = Column(String(255), nullable=True)
    safety_wait_period = Column(String(100), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class MarketplaceOrderModel(Base):
    __tablename__ = "marketplace_orders"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    order_id = Column(String(64), unique=True, nullable=False, index=True)
    farmer_id = Column(UUID(as_uuid=True), ForeignKey("farmers.id", ondelete="SET NULL"), nullable=True, index=True)
    recipient_name = Column(String(255), nullable=False)
    recipient_phone_masked = Column(String(32), nullable=False)  # Privacy-masked (e.g. +91 98*** **345)
    phone_hash = Column(String(64), nullable=True, index=True)   # Salted SHA-256 for lookup without PII leak
    delivery_address = Column(Text, nullable=False)
    delivery_pincode = Column(String(10), nullable=False, index=True)
    payment_method = Column(String(100), nullable=False)
    payment_status = Column(String(50), nullable=False, default="PAID")
    subtotal = Column(Float, nullable=False)
    delivery_fee = Column(Float, nullable=False, default=0.0)
    marketplace_fee = Column(Float, nullable=False, default=5.0)
    subsidy = Column(Float, nullable=False, default=0.0)
    coupon_discount = Column(Float, nullable=False, default=0.0)
    coupon_code = Column(String(50), nullable=True)
    total_paid = Column(Float, nullable=False)
    diamonds_earned = Column(Integer, default=0)
    status = Column(String(50), nullable=False, default="CONFIRMED")  # CONFIRMED, PACKED, DISPATCHED, OUT_FOR_DELIVERY, DELIVERED, CANCELLED
    delivery_otp = Column(String(6), nullable=False)
    tracking_number = Column(String(64), nullable=False, index=True)
    tamper_checksum = Column(String(64), nullable=False)              # HMAC-SHA256 non-repudiation signature
    items_json = Column(Text, nullable=False)                         # JSON array of ordered items & specs
    instructions = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    farmer = relationship("Farmer", backref="marketplace_orders")


class MarketplaceCoupon(Base):
    __tablename__ = "marketplace_coupons"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    code = Column(String(32), unique=True, nullable=False, index=True)
    title = Column(String(255), nullable=False)
    discount_percent = Column(Float, default=0.0)
    flat_discount = Column(Float, default=0.0)
    max_discount = Column(Float, default=150.0)
    min_order_amount = Column(Float, default=299.0)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
