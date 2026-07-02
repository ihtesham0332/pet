import uuid
from datetime import datetime, timezone

from sqlalchemy import String, Column, DateTime, Text, Numeric, Date, ForeignKey, Uuid
from sqlalchemy.orm import relationship

from app.database import Base


class Pet(Base):
    __tablename__ = "pets"

    id = Column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id = Column(Uuid, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    species = Column(String(100), nullable=False)
    breed = Column(String(255), nullable=True)
    date_of_birth = Column(Date, nullable=True)
    weight_kg = Column(Numeric(5, 2), nullable=True)
    medical_history = Column(Text, nullable=True)
    avatar_url = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    owner = relationship("User", backref="pets")
