import os
import logging
from typing import Optional
import firebase_admin
from firebase_admin import credentials, storage
from app.core.config import settings

logger = logging.getLogger("aarogya_vault_storage")

class FirebaseStorageProvider:
    def __init__(self):
        self.bucket_name = settings.FIREBASE_STORAGE_BUCKET
        self.project_id = settings.FIREBASE_PROJECT_ID
        self.credentials_path = settings.FIREBASE_CREDENTIALS_PATH
        
        self.uploads_dir = os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
            "app",
            "uploads"
        )
        os.makedirs(self.uploads_dir, exist_ok=True)
        
        self.initialized = False
        
        if self.bucket_name:
            try:
                # Check if default app is already initialized
                firebase_admin.get_app()
                self.initialized = True
            except ValueError:
                # App not initialized, proceed to initialize
                if self.credentials_path and os.path.exists(self.credentials_path):
                    try:
                        cred = credentials.Certificate(self.credentials_path)
                        firebase_admin.initialize_app(cred, {
                            'storageBucket': f"{self.bucket_name}"
                        })
                        self.initialized = True
                        logger.info("Firebase Storage initialized successfully using credentials certificate.")
                    except Exception as e:
                        logger.error(f"Failed to initialize Firebase Storage certificate: {e}")
                else:
                    try:
                        # Fallback to default application credentials
                        firebase_admin.initialize_app(options={
                            'storageBucket': f"{self.bucket_name}"
                        })
                        self.initialized = True
                        logger.info("Firebase Storage initialized successfully using default credentials.")
                    except Exception as e:
                        logger.warning(f"Firebase Storage default initialization skipped/failed: {e}")
        else:
            logger.warning("FIREBASE_STORAGE_BUCKET environment variable is not set. Falling back to local storage.")

    def upload_file(self, file_path: str, destination_name: str) -> Optional[str]:
        """Uploads a file to Firebase Storage and returns its signed download URL, or fallback local path."""
        if not os.path.exists(file_path):
            logger.error(f"File not found for upload: {file_path}")
            return None

        if self.initialized:
            try:
                bucket = storage.bucket()
                blob = bucket.blob(destination_name)
                
                # Check file size (20MB limit)
                file_size = os.path.getsize(file_path)
                if file_size > settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024:
                    raise ValueError(f"File size exceeds limit of {settings.MAX_UPLOAD_SIZE_MB}MB")
                
                # Set content type depending on extension
                content_type = "application/pdf"
                if destination_name.endswith(('.png', '.PNG')):
                    content_type = "image/png"
                elif destination_name.endswith(('.jpg', '.jpeg', '.JPG', '.JPEG')):
                    content_type = "image/jpeg"
                
                blob.upload_from_filename(file_path, content_type=content_type)
                
                # Generate a secure signed URL valid for 7 days (maximum expiration)
                url = blob.generate_signed_url(expiration=3600 * 24 * 7)
                logger.info(f"Successfully uploaded {destination_name} to Firebase Storage.")
                return url
            except Exception as e:
                logger.error(f"Firebase upload failed for {destination_name}: {e}. Falling back to local.")
                return self._copy_local(file_path, destination_name)
        else:
            return self._copy_local(file_path, destination_name)

    def _copy_local(self, source_path: str, filename: str) -> str:
        """Fallback helper to serve files locally during development."""
        import shutil
        dest = os.path.join(self.uploads_dir, filename)
        if source_path != dest:
            shutil.copy2(source_path, dest)
        
        # Build local URL using API_BASE_URL (removing /api/v1 prefix)
        base = settings.API_BASE_URL
        if base.endswith("/api/v1"):
            base = base[:-7]
        elif base.endswith("/api/v1/"):
            base = base[:-8]
        return f"{base}/uploads/{filename}"

    def get_download_url(self, filename: str) -> str:
        """Returns signed URL for viewing/downloading the file, or fallback local path."""
        if self.initialized:
            try:
                bucket = storage.bucket()
                blob = bucket.blob(filename)
                url = blob.generate_signed_url(expiration=3600)  # 1 hour validity
                return url
            except Exception:
                pass
        
        # Fallback local path
        base = settings.API_BASE_URL
        if base.endswith("/api/v1"):
            base = base[:-7]
        elif base.endswith("/api/v1/"):
            base = base[:-8]
        return f"{base}/uploads/{filename}"

firebase_storage = FirebaseStorageProvider()
