import uuid
from datetime import datetime, timezone

from sqlalchemy import String, Column, DateTime, Text, Numeric, ForeignKey, Uuid
from sqlalchemy.orm import relationship

from app.database import Base


class WeightRecord(Base):
    __tablename__ = "weight_records"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4)
    pet_id = Column(Uuid, ForeignKey("pets.id", ondelete="CASCADE"), nullable=False, index=True)
    weight_kg = Column(Numeric(5, 2), nullable=False)
    measured_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    pet = relationship("Pet", backref="weight_records")
