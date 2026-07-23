import logging
from twilio.rest import Client
from app.core.config import settings

logger = logging.getLogger("aarogya_vault_sms")

class TwilioSMSProvider:
    def __init__(self):
        self.account_sid = settings.TWILIO_ACCOUNT_SID
        self.auth_token = settings.TWILIO_AUTH_TOKEN
        self.service_sid = settings.TWILIO_VERIFY_SERVICE_SID
        
        self.client = None
        if self.account_sid and self.auth_token:
            try:
                self.client = Client(self.account_sid, self.auth_token)
            except Exception as e:
                logger.error(f"Failed to initialize Twilio Client: {e}")

    def send_verification_otp(self, phone: str) -> str:
        """Sends an OTP code via Twilio Verify API and returns verification SID."""
        if not self.client:
            raise ValueError("Twilio credentials (TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN) are not configured.")
        if not self.service_sid:
            raise ValueError("Twilio Verify Service SID (TWILIO_VERIFY_SERVICE_SID) is not configured.")
            
        try:
            # Twilio Verify handles OTP generation & delivery natively
            verification = self.client.verify.v2.services(self.service_sid) \
                                                .verifications \
                                                .create(to=phone, channel='sms')
            logger.info(f"Verification OTP sent successfully to {phone}. SID: {verification.sid}")
            return verification.sid
        except Exception as e:
            logger.error(f"Failed to send Twilio Verify OTP to {phone}: {e}")
            raise RuntimeError(f"Twilio Verify API Error: {str(e)}")

    def check_verification_otp(self, phone: str, code: str) -> bool:
        """Verifies the OTP code via Twilio Verify API check."""
        if not self.client:
            raise ValueError("Twilio credentials are not configured.")
        if not self.service_sid:
            raise ValueError("Twilio Verify Service SID is not configured.")
            
        try:
            check = self.client.verify.v2.services(self.service_sid) \
                                         .verification_checks \
                                         .create(to=phone, code=code)
            
            logger.info(f"OTP check for {phone} completed with status: {check.status}")
            return check.status == "approved"
        except Exception as e:
            logger.error(f"Failed to verify Twilio OTP for {phone}: {e}")
            raise RuntimeError(f"Twilio Verify Check Error: {str(e)}")

sms_provider = TwilioSMSProvider()
