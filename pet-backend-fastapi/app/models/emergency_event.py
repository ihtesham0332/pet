import uuid
from datetime import datetime, timezone

from sqlalchemy import String, Column, DateTime, Text, Boolean, ForeignKey, Uuid, JSON
from sqlalchemy.orm import relationship

from app.database import Base


class EmergencyEvent(Base):
    __tablename__ = "emergency_events"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4)
    pet_id = Column(Uuid, ForeignKey("pets.id", ondelete="CASCADE"), nullable=False, index=True)
    severity = Column(String(50), nullable=False)
    red_flags = Column(JSON, nullable=True)
    action_taken = Column(Text, nullable=True)
    status = Column(String(50), default="active")
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    resolved_at = Column(DateTime(timezone=True), nullable=True)

    pet = relationship("Pet", backref="emergency_events")
