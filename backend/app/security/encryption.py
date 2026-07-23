import base64
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding

from app.core.config import settings

# Use key and IV matching Flutter's SecurityHelper
KEY = settings.AES_ENCRYPTION_KEY
IV = settings.AES_ENCRYPTION_IV

def encrypt_data(data: str) -> str:
    """Encrypts clear text using AES-256-CBC PKCS7 matching Flutter client."""
    try:
        padder = padding.PKCS7(128).padder()
        padded_data = padder.update(data.encode('utf-8')) + padder.finalize()
        cipher = Cipher(algorithms.AES(KEY), modes.CBC(IV))
        encryptor = cipher.encryptor()
        ct = encryptor.update(padded_data) + encryptor.finalize()
        return base64.b64encode(ct).decode('utf-8')
    except Exception:
        return ""

def decrypt_data(encrypted_data: str) -> str:
    """Decrypts AES-256-CBC PKCS7 encrypted text."""
    try:
        ct = base64.b64decode(encrypted_data.encode('utf-8'))
        cipher = Cipher(algorithms.AES(KEY), modes.CBC(IV))
        decryptor = cipher.decryptor()
        padded_data = decryptor.update(ct) + decryptor.finalize()
        unpadder = padding.PKCS7(128).unpadder()
        data = unpadder.update(padded_data) + unpadder.finalize()
        return data.decode('utf-8')
    except Exception:
        return ""
