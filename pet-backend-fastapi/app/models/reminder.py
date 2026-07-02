import uuid
from datetime import datetime, timezone

from sqlalchemy import String, Column, DateTime, Text, Boolean, ForeignKey, Uuid
from sqlalchemy.orm import relationship

from app.database import Base


class Reminder(Base):
    __tablename__ = "reminders"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id = Column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    pet_id = Column(Uuid, ForeignKey("pets.id", ondelete="CASCADE"), nullable=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    reminder_type = Column(String(50), nullable=False, default="checkup")
    scheduled_date = Column(DateTime(timezone=True), nullable=False)
    status = Column(String(50), default="pending")
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", backref="reminders")
    pet = relationship("Pet", backref="reminders")
