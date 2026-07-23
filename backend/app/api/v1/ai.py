from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User, LabReport, Profile, AuditLog, AIChatMessage, ConsentSetting
from app.schemas.schemas import AIQueryRequest, AIExplanationResponse, AIChatMessageResponse
from app.services.ai import ai_service

router = APIRouter(prefix="/ai", tags=["ai"])

@router.post("/chat", response_model=AIExplanationResponse)
def chat_assistant(request: AIQueryRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Health Assistant chat endpoint, evaluating user consent and saving history."""
    consent = db.query(ConsentSetting).filter(ConsentSetting.user_id == current_user.id).first()
    context = request.context or ""
    
    if consent:
        if not consent.allow_ai_profile_read:
            context = "Consent Denied: AI has no permission to read patient profile metadata."
        if not consent.allow_ai_records_read:
            if not consent.allow_ai_profile_read:
                context = "Consent Denied: AI has no permission to read patient profile or medical history/reports."
            else:
                context = f"Consent Denied: AI has no permission to read patient reports/history. User Profile context: {context.split('Allergies')[0] if 'Allergies' in context else context}"

    explanation = ai_service.generate_health_insight(request.prompt, context)
    
    # Save message history to DB
    user_msg = AIChatMessage(user_id=current_user.id, message=request.prompt, is_user=True)
    ai_msg = AIChatMessage(user_id=current_user.id, message=explanation, is_user=False)
    db.add(user_msg)
    db.add(ai_msg)
    
    audit = AuditLog(user_id=current_user.id, action="AI_CHAT", details=f"AI chat request. Prompt length: {len(request.prompt)}")
    db.add(audit)
    db.commit()
    
    return AIExplanationResponse(explanation=explanation)

@router.get("/chat-history", response_model=List[AIChatMessageResponse])
def get_chat_history(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Fetches chat history list, seeding welcoming default message if empty."""
    messages = db.query(AIChatMessage).filter(AIChatMessage.user_id == current_user.id).order_by(AIChatMessage.timestamp.asc()).all()
    if not messages:
        profile_name = current_user.profile.full_name if current_user.profile else 'Patient'
        default_text = f"Hello, {profile_name}! I am your Aarogya Vault AI Health Assistant. How can I help you today? You can ask me to explain a report, outline a medicine schedule, or provide general wellness tips."
        welcome_msg = AIChatMessage(user_id=current_user.id, message=default_text, is_user=False)
        db.add(welcome_msg)
        db.commit()
        db.refresh(welcome_msg)
        return [welcome_msg]
    return messages

@router.delete("/chat-history")
def clear_chat_history(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Clears user chat logs and audits action."""
    db.query(AIChatMessage).filter(AIChatMessage.user_id == current_user.id).delete()
    
    audit = AuditLog(user_id=current_user.id, action="CLEAR_AI_HISTORY", details="Cleared AI Chat History")
    db.add(audit)
    db.commit()
    return {"success": True, "message": "Chat history cleared successfully"}

@router.post("/explain-report/{report_id}", response_model=AIExplanationResponse)
def explain_report(report_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Explains a clinical report, respecting privacy consent parameters."""
    consent = db.query(ConsentSetting).filter(ConsentSetting.user_id == current_user.id).first()
    if consent and not consent.allow_ai_records_read:
        return AIExplanationResponse(explanation="AI Explanation blocked: Consent for AI read-only access to medical records is disabled in Settings.")

    report = db.query(LabReport).filter(LabReport.id == report_id, LabReport.user_id == current_user.id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
        
    context = f"Report Title: {report.title}, Date: {report.date}, Type: {report.type}, Status: {report.status}."
    prompt = f"Provide a complete, readable explanation of my diagnostic report: {report.title}."
    
    explanation = ai_service.generate_health_insight(prompt, context)
    return AIExplanationResponse(explanation=explanation)

@router.get("/summary", response_model=AIExplanationResponse)
def get_patient_summary(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Generates health records summaries for the patient."""
    consent = db.query(ConsentSetting).filter(ConsentSetting.user_id == current_user.id).first()
    if consent and (not consent.allow_ai_records_read or not consent.allow_ai_profile_read):
         return AIExplanationResponse(explanation="AI Summary blocked: Privacy settings block AI assistant from loading profile or clinical records details.")

    profile = db.query(Profile).filter(Profile.user_id == current_user.id).first()
    reports = db.query(LabReport).filter(LabReport.user_id == current_user.id).all()
    
    context = f"Patient Profile: Name={profile.full_name if profile else 'N/A'}, Blood={profile.blood_group if profile else 'N/A'}. Reports count: {len(reports)}."
    prompt = "Generate a general health summary, risk analysis, and timeline."
    
    explanation = ai_service.generate_health_insight(prompt, context)
    return AIExplanationResponse(explanation=explanation)
