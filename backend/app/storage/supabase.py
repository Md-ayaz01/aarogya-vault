import os
import logging
import httpx
from typing import Optional
from app.core.config import settings

logger = logging.getLogger("aarogya_vault_supabase_storage")

class SupabaseStorageProvider:
    def __init__(self):
        # We strip "/rest/v1" or similar path segments to get the base domain URL
        url_input = settings.SUPABASE_URL or ""
        if "/rest/v1" in url_input:
            self.supabase_url = url_input.split("/rest/v1")[0].rstrip("/")
        else:
            self.supabase_url = url_input.rstrip("/")
            
        self.service_role_key = settings.SUPABASE_SERVICE_ROLE_KEY
        self.bucket_name = settings.SUPABASE_STORAGE_BUCKET
        
        # Local upload folder fallback
        self.uploads_dir = os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
            "app",
            "uploads"
        )
        os.makedirs(self.uploads_dir, exist_ok=True)
        
        self.initialized = bool(self.supabase_url and self.service_role_key and self.bucket_name)
        if not self.initialized:
            logger.warning("SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY or SUPABASE_STORAGE_BUCKET is not set. Falling back to local storage.")

    def upload_file(self, local_file_path: str, destination_name: str) -> Optional[str]:
        """Uploads a file to Supabase Storage and returns its storage path or filename."""
        if not self.initialized or not os.path.exists(local_file_path):
            # Fallback to local directory
            dest_path = os.path.join(self.uploads_dir, destination_name)
            try:
                import shutil
                shutil.copy(local_file_path, dest_path)
                logger.info(f"Local fallback: saved file to {dest_path}")
                return f"/uploads/{destination_name}"
            except Exception as e:
                logger.error(f"Local fallback failed: {e}")
                return None

        try:
            url = f"{self.supabase_url}/storage/v1/object/{self.bucket_name}/{destination_name}"
            headers = {
                "Authorization": f"Bearer {self.service_role_key}",
                "ApiKey": self.service_role_key,
                "Content-Type": "application/octet-stream"
            }
            with open(local_file_path, "rb") as f:
                file_data = f.read()
                
            response = httpx.post(url, headers=headers, content=file_data, timeout=30.0)
            if response.status_code in (200, 201):
                logger.info(f"Successfully uploaded {destination_name} to Supabase Storage.")
                return destination_name
            else:
                logger.error(f"Supabase Storage upload failed with status {response.status_code}: {response.text}")
                # Fallback to local
                dest_path = os.path.join(self.uploads_dir, destination_name)
                import shutil
                shutil.copy(local_file_path, dest_path)
                return f"/uploads/{destination_name}"
        except Exception as e:
            logger.error(f"Supabase Storage upload exception: {e}")
            # Fallback to local
            try:
                dest_path = os.path.join(self.uploads_dir, destination_name)
                import shutil
                shutil.copy(local_file_path, dest_path)
                return f"/uploads/{destination_name}"
            except Exception:
                return None

    def get_download_url(self, file_name: str) -> str:
        """Generates a short-lived signed secure download URL for reports."""
        if not self.initialized:
            # Local fallback URL
            return f"/uploads/{file_name}"
            
        if file_name.startswith("/uploads/"):
            return file_name

        try:
            url = f"{self.supabase_url}/storage/v1/object/sign/{self.bucket_name}/{file_name}"
            headers = {
                "Authorization": f"Bearer {self.service_role_key}",
                "ApiKey": self.service_role_key,
                "Content-Type": "application/json"
            }
            # Short-lived signed URL (10 minutes)
            body = {"expiresIn": 600}
            response = httpx.post(url, headers=headers, json=body, timeout=10.0)
            if response.status_code == 200:
                data = response.json()
                signed_path = data.get("signedURL") or data.get("signedUrl")
                if signed_path:
                    if signed_path.startswith("/"):
                        return f"{self.supabase_url}{signed_path}"
                    return signed_path
            logger.error(f"Failed to generate Supabase signed URL (status {response.status_code}): {response.text}")
        except Exception as e:
            logger.error(f"Exception generating signed URL: {e}")
            
        return f"/uploads/{file_name}"

supabase_storage = SupabaseStorageProvider()
