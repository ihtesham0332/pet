import uuid
from datetime import datetime, timezone

from sqlalchemy import String, Column, DateTime, Text, Boolean, ForeignKey, Uuid, JSON
from sqlalchemy.orm import relationship

from app.database import Base


class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4)
    pet_id = Column(Uuid, ForeignKey("pets.id", ondelete="CASCADE"), nullable=False, index=True)
    vet_name = Column(String(255), nullable=False)
    vet_clinic = Column(String(255), nullable=True)
    scheduled_at = Column(DateTime(timezone=True), nullable=False)
    status = Column(String(50), default="pending")
    type = Column(String(100), default="telehealth")
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    pet = relationship("Pet", backref="appointments")
