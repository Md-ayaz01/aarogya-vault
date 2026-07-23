import logging

logger = logging.getLogger("aarogya_vault_email")

class EmailProvider:
    def send_email(self, to_email: str, subject: str, body: str) -> bool:
        """Placeholder for enterprise email notification service."""
        logger.info(f"Email service not configured. Queueing mock email to {to_email} with subject: {subject}")
        return True

email_provider = EmailProvider()
