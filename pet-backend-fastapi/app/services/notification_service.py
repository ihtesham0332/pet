from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.notification import Notification


class NotificationService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(
        self, user_id: str, type: str, title: str, body: str = None, payload: dict = None
    ) -> Notification:
        notif = Notification(
            user_id=user_id,
            type=type,
            title=title,
            body=body,
            payload=payload,
        )
        self.db.add(notif)
        await self.db.commit()
        await self.db.refresh(notif)
        return notif

    async def get_unread_count(self, user_id: str) -> int:
        result = await self.db.execute(
            select(Notification).where(
                Notification.user_id == user_id, Notification.read == False
            )
        )
        return len(result.scalars().all())

    async def mark_read(self, notification_id: str, user_id: str) -> None:
        result = await self.db.execute(
            select(Notification).where(
                Notification.id == notification_id, Notification.user_id == user_id
            )
        )
        notif = result.scalar_one_or_none()
        if notif:
            notif.read = True
            await self.db.commit()
