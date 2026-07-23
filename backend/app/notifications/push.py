import logging

logger = logging.getLogger("aarogya_vault_push")

class PushProvider:
    def send_push_notification(self, user_id: int, title: str, body: str) -> bool:
        """Placeholder for enterprise mobile push notification service (e.g. Firebase Cloud Messaging)."""
        logger.info(f"Push notification service not configured. Queueing mock push to User {user_id}: {title}")
        return True

push_provider = PushProvider()
