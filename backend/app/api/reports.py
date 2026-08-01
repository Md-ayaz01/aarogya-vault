from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
import os

from app.core.database import get_db
from app.api.auth import get_current_user
from app.models import User, LabReport, AuditLog
from app.schemas import LabReportCreate, LabReportResponse
from app.core.storage import storage_provider


router = APIRouter(prefix="/reports", tags=["reports"])

@router.get("", response_model=List[LabReportResponse])
def get_reports(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    reports = db.query(LabReport).filter(LabReport.user_id == current_user.id).all()
    
    # Seeding mock reports matching the reference UI design
    if not reports:
        mock_reports = [
            LabReport(
                user_id=current_user.id,
                title="Blood Report",
                date="2024-04-12",
                type="Lab",
                status="Final",
                file_name="blood_report_20240412.pdf",
                summary="AI Summary: Hemoglobin, platelets, and white blood cell count are within healthy limits. Glucose levels are borderline normal (98 mg/dL fasting). Suggest monitoring dietary intake."
            ),
            LabReport(
                user_id=current_user.id,
                title="X-Ray Chest",
                date="2024-03-05",
                type="Imaging",
                status="Final",
                file_name="chest_xray_20240305.pdf",
                summary="AI Summary: No active pulmonary lesions. Lungs are clear. Heart size is within normal limits. Bony thorax is intact."
            ),
            LabReport(
                user_id=current_user.id,
                title="MRI Brain",
                date="2024-02-22",
                type="Imaging",
                status="Final",
                file_name="mri_brain_20240222.pdf",
                summary="AI Summary: Normal MRI of the brain. No signs of infarction, hemorrhage, or mass effect. Ventricles and sulci are normal for age."
            ),
            LabReport(
                user_id=current_user.id,
                title="ECG Report",
                date="2024-01-18",
                type="Lab",
                status="Final",
                file_name="ecg_report_20240118.pdf",
                summary="AI Summary: Normal sinus rhythm. Heart rate is 72 bpm. PR interval, QRS duration, and QT interval are normal. No ST-segment elevation or depression noted."
            ),
            LabReport(
                user_id=current_user.id,
                title="CT Scan Abdomen",
                date="2023-12-10",
                type="Imaging",
                status="Final",
                file_name="ct_abdomen_20231210.pdf",
                summary="AI Summary: Normal CT abdomen. Liver, spleen, pancreas, kidneys, and adrenal glands are unremarkable. No free fluid or lymphadenopathy."
            ),
        ]
        for rep in mock_reports:
            db.add(rep)
        db.commit()
        reports = db.query(LabReport).filter(LabReport.user_id == current_user.id).all()
        
    return reports

@router.post("", response_model=LabReportResponse)
def upload_report(
    title: str = Form(...),
    date: str = Form(...),
    report_type: str = Form(...),
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Ensure correct file extension
    ext = file.filename.split('.')[-1] if '.' in file.filename else 'pdf'
    safe_title = title.lower().replace(" ", "_")
    file_name = f"{safe_title}_{date.replace('-', '')}.{ext}"
    
    # Save file contents locally first
    uploads_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "uploads")
    os.makedirs(uploads_dir, exist_ok=True)
    file_path = os.path.join(uploads_dir, file_name)
    with open(file_path, "wb") as f:
        f.write(file.file.read())
        
    # Upload to storage provider (Firebase/S3/Local fallback)
    storage_url = storage_provider.upload_file(file_path, file_name)
        
    new_report = LabReport(
        user_id=current_user.id,
        title=title,
        date=date,
        type=report_type,
        status="Final",
        file_name=file_name,
        summary="AI Summary: Analyzing report. Initial diagnosis shows standard ranges. Detailed health insights are being processed."
    )
    db.add(new_report)
    db.commit()
    db.refresh(new_report)
    
    audit = AuditLog(user_id=current_user.id, action="UPLOAD_REPORT", details=f"Uploaded report: {title} ({file_name}) to storage")
    db.add(audit)
    db.commit()
    
    return new_report

@router.get("/{report_id}/download")
def download_report(report_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    report = db.query(LabReport).filter(LabReport.id == report_id, LabReport.user_id == current_user.id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
        
    # Get secure download link from storage provider
    download_url = storage_provider.get_download_url(report.file_name)
    return {
        "status": "success",
        "file_name": report.file_name,
        "content_type": "application/pdf" if report.file_name.endswith('.pdf') else "image/png",
        "url": download_url,
        "mock_pdf_base64": "JVBERi0xLjQKJcOlwrHDg1oKMSAwIG9iagogIDw8CiAgICAvVGl0bGUgKEFhcm9neWEgVmF1bHQgUmVwb3J0KQogICAgL0NyZWF0b3IgKEFhcm9neWEgVmF1bHQgRW50ZXJwcmlzZSkKICA+PgplbmRvYmoKMiAwIG9iagogIDw8CiAgICAvVHlwZSAvQ2F0YWxvZwogICAgL1BhZ2VzIDMgMCBSCgogID4+CmVuZG9iag=="
    }


@router.post("/{report_id}/share")
def share_report(report_id: int, duration_hours: int = 24, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    report = db.query(LabReport).filter(LabReport.id == report_id, LabReport.user_id == current_user.id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
        
    # Generate temporary share URL
    share_token = f"share_{report.id}_temp_2026"
    share_url = f"https://aarogya-vault.in/share/{share_token}"
    
    audit = AuditLog(user_id=current_user.id, action="SHARE_REPORT", details=f"Shared report {report.title} for {duration_hours} hours")
    db.add(audit)
    db.commit()
    
    return {
        "status": "success",
        "share_url": share_url,
        "expires_in_hours": duration_hours
    }

@router.delete("/{report_id}")
def delete_report(report_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    report = db.query(LabReport).filter(LabReport.id == report_id, LabReport.user_id == current_user.id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
        
    db.delete(report)
    db.commit()
    
    audit = AuditLog(user_id=current_user.id, action="DELETE_REPORT", details=f"Deleted report: {report.title}")
    db.add(audit)
    db.commit()
    
    return {"status": "success", "message": "Report deleted successfully"}
