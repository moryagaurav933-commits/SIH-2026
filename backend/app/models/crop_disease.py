"""
SQLAlchemy models for Crop Disease Knowledge Base and ML Class Mapping.
Matches disease_database.sql schema for PostgreSQL and SQLite.
"""
from sqlalchemy import Column, String, Integer, Text, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base import Base


class Crop(Base):
    __tablename__ = "crops"

    crop_id = Column(String(50), primary_key=True)
    crop_name = Column(String(100), nullable=False)

    diseases = relationship("Disease", back_populates="crop", cascade="all, delete-orphan")


class Disease(Base):
    __tablename__ = "diseases"

    disease_id = Column(String(100), primary_key=True)
    crop_id = Column(String(50), ForeignKey("crops.crop_id"), nullable=False)
    disease_name = Column(String(255), nullable=False)
    scientific_name_or_pathogen = Column(Text, nullable=True)
    description = Column(Text, nullable=True)
    cause = Column(Text, nullable=True)
    severity = Column(Text, nullable=True)
    farmer_action = Column(Text, nullable=True)

    crop = relationship("Crop", back_populates="diseases")
    symptoms = relationship("DiseaseSymptom", back_populates="disease", cascade="all, delete-orphan")
    healthy_signs = relationship("HealthySign", back_populates="disease", cascade="all, delete-orphan")
    favorable_conditions = relationship("FavorableCondition", back_populates="disease", cascade="all, delete-orphan")
    treatments = relationship("Treatment", back_populates="disease", cascade="all, delete-orphan")
    prevention_steps = relationship("PreventionStep", back_populates="disease", cascade="all, delete-orphan")
    sources = relationship("Source", back_populates="disease", cascade="all, delete-orphan")
    ml_mappings = relationship("MLClassMapping", back_populates="disease", cascade="all, delete-orphan")


class DiseaseSymptom(Base):
    __tablename__ = "disease_symptoms"

    id = Column(Integer, primary_key=True, autoincrement=True)
    disease_id = Column(String(100), ForeignKey("diseases.disease_id", ondelete="CASCADE"), nullable=False)
    symptom_text = Column(Text, nullable=False)

    disease = relationship("Disease", back_populates="symptoms")


class HealthySign(Base):
    __tablename__ = "healthy_signs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    disease_id = Column(String(100), ForeignKey("diseases.disease_id", ondelete="CASCADE"), nullable=False)
    sign_text = Column(Text, nullable=False)

    disease = relationship("Disease", back_populates="healthy_signs")


class FavorableCondition(Base):
    __tablename__ = "favorable_conditions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    disease_id = Column(String(100), ForeignKey("diseases.disease_id", ondelete="CASCADE"), nullable=False)
    condition_text = Column(Text, nullable=False)

    disease = relationship("Disease", back_populates="favorable_conditions")


class Treatment(Base):
    __tablename__ = "treatments"

    id = Column(Integer, primary_key=True, autoincrement=True)
    disease_id = Column(String(100), ForeignKey("diseases.disease_id", ondelete="CASCADE"), nullable=False)
    category = Column(String(50), nullable=False)  # cultural, chemical, biological
    treatment_text = Column(Text, nullable=False)

    disease = relationship("Disease", back_populates="treatments")


class PreventionStep(Base):
    __tablename__ = "prevention_steps"

    id = Column(Integer, primary_key=True, autoincrement=True)
    disease_id = Column(String(100), ForeignKey("diseases.disease_id", ondelete="CASCADE"), nullable=False)
    prevention_text = Column(Text, nullable=False)

    disease = relationship("Disease", back_populates="prevention_steps")


class Source(Base):
    __tablename__ = "sources"

    id = Column(Integer, primary_key=True, autoincrement=True)
    disease_id = Column(String(100), ForeignKey("diseases.disease_id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    organization = Column(String(255), nullable=True)
    url = Column(Text, nullable=True)

    disease = relationship("Disease", back_populates="sources")


class MLClassMapping(Base):
    __tablename__ = "ml_class_mapping"

    id = Column(Integer, primary_key=True, autoincrement=True)
    ml_class_name = Column(String(255), unique=True, nullable=False)
    disease_id = Column(String(100), ForeignKey("diseases.disease_id"), nullable=False)

    disease = relationship("Disease", back_populates="ml_mappings")
