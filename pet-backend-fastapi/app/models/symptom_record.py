import uuid
from datetime import datetime, timezone

from sqlalchemy import String, Column, DateTime, Text, Boolean, ForeignKey, Uuid, JSON
from sqlalchemy.orm import relationship

from app.database import Base


class SymptomRecord(Base):
    __tablename__ = "symptom_records"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4)
    pet_id = Column(Uuid, ForeignKey("pets.id", ondelete="CASCADE"), nullable=False, index=True)
    symptoms_text = Column(Text, nullable=False)
    image_urls = Column(JSON, nullable=True)
    voice_url = Column(Text, nullable=True)
    ai_diagnosis = Column(JSON, nullable=True)
    risk_level = Column(String(50), nullable=True)
    is_emergency = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    pet = relationship("Pet", backref="symptom_records")
