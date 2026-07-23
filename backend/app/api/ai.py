from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import google.generativeai as genai
from typing import Optional, List
from datetime import datetime

from app.core.database import get_db
from app.api.auth import get_current_user
from app.models import User, LabReport, Profile, AuditLog, AIChatMessage, ConsentSetting
from app.schemas import AIQueryRequest, AIExplanationResponse, AIChatMessageResponse
from app.core.config import settings


router = APIRouter(prefix="/ai", tags=["ai"])

# Initialize Gemini with Gemini 1.5 Flash if API key is provided
if settings.GEMINI_API_KEY:
    genai.configure(api_key=settings.GEMINI_API_KEY)

def generate_gemini_content(prompt: str, context: Optional[str] = None) -> str:
    if not settings.GEMINI_API_KEY:
        # Fallback simulation engine
        return simulate_ai_response(prompt, context)
        
    try:
        # Use latest production model gemini-1.5-flash with system instruction parameters
        model = genai.GenerativeModel(
            model_name="gemini-1.5-flash",
            system_instruction="You are Aarogya Vault's elite AI Health Assistant. "
                               "Your goal is to explain medical parameters, lab reports, imaging scans, and prescriptions "
                               "in plain, accessible, and structured terms. Focus on diet, lifestyle, and dosage safety. "
                               "Always preface clinical details by stating that your insights are for educational purposes "
                               "only and the patient should verify critical changes with their treating physician."
        )
        full_prompt = f"Patient context metadata: {context or 'None'}\n\nQuery: {prompt}"
        response = model.generate_content(full_prompt)
        return response.text
    except Exception as e:
        return f"[Gemini API connection error - Offline fallback]:\n{simulate_ai_response(prompt, context)}"

def simulate_ai_response(prompt: str, context: Optional[str] = None) -> str:
    prompt_lower = prompt.lower()
    
    if "blood report" in prompt_lower or "explain my report" in prompt_lower:
        return (
            "### AI Lab Report Analysis (Aarogya Vault)\n\n"
            "*Notice: For informational purposes only. Consult Dr. Ravi Sharma for medical advice.*\n\n"
            "Based on your **Blood Report** (April 12, 2024):\n\n"
            "1. **Glycemic Control**: Fasting glucose is **98 mg/dL**. While technically within the normal reference range (< 100 mg/dL), it borders on pre-diabetic thresholds. We suggest limiting processed carbohydrates and snacking.\n"
            "2. **Lipid Profile**: Total cholesterol is **185 mg/dL** (Normal), but LDL is slightly elevated at **115 mg/dL**. Focus on increasing heart-healthy fats (omega-3s) and fiber.\n"
            "3. **Hematology**: Hemoglobin (**14.2 g/dL**) and Platelet count are excellent and show zero signs of anemia or infection.\n\n"
            "**Recommended Steps**: Monitor glucose fasting levels in 6 months, maintain 150 minutes of aerobic exercise weekly, and limit dessert intake."
        )
    elif "mri" in prompt_lower or "brain" in prompt_lower:
        return (
            "### AI Scan Explanation (MRI Brain)\n\n"
            "*Notice: This is a diagnostic summary. Verify structural changes with your specialist.*\n\n"
            "Your **MRI Brain** scan from **February 22, 2024** indicates a healthy result:\n\n"
            "- **Brain Structures**: Cerebral hemispheres, cerebellum, and brainstem are structurally intact.\n"
            "- **Vessels & Ventricles**: No evidence of masses, infarctions, blockages, or intracranial bleeding.\n\n"
            "**Insights**: If you are experiencing persistent headaches, structural causes are ruled out by this scan. Consider monitoring eye strain, sleep quality, or hydration."
        )
    elif "paracetamol" in prompt_lower or "medicine explanation" in prompt_lower or "azithromycin" in prompt_lower:
        return (
            "### AI Medication Analysis\n\n"
            "Here is the breakdown of your active prescription drugs:\n\n"
            "1. **Paracetamol 650mg** (Antipyretic/Analgesic):\n"
            "   - *Purpose*: Treats fever and relieves muscle pain.\n"
            "   - *Guideline*: Take 1 tablet after food as scheduled (1-0-1). Do not exceed 4g per day to protect liver health.\n\n"
            "2. **Azithromycin 500mg** (Macrolide Antibiotic):\n"
            "   - *Purpose*: Treats throat/respiratory bacterial infections.\n"
            "   - *Guideline*: Must complete the full 3-day course (0-0-1) to prevent antibiotic resistance, even if fever drops.\n\n"
            "3. **Cetirizine 10mg** (Antihistamine):\n"
            "   - *Purpose*: Reduces allergy symptoms (runny nose, throat itch).\n"
            "   - *Guideline*: Take before sleep (0-0-1) due to potential mild drowsiness."
        )
    elif "symptom" in prompt_lower:
        return (
            "### AI Symptom Guidance (Informational Only)\n\n"
            "If you are experiencing fever, fatigue, or sore throat:\n"
            "- **Hydration**: Drink plenty of warm water or electrolytes.\n"
            "- **Rest**: Keep physical exertion minimal for 48 hours.\n"
            "- **Medications**: Use Paracetamol as prescribed to manage body temperatures.\n\n"
            "*CAUTION*: Go to the emergency clinic immediately if you experience shortness of breath, chest pressure, or a persistent high fever (>103°F) that does not respond to medication."
        )
    else:
        return (
            "### Aarogya Vault AI Health Assistant\n\n"
            "Hello! I am your AI clinical assistant. I have secure, read-only access to your medical dashboard. "
            "I can help you:\n"
            "- Summarize your lab reports (e.g. Glucose levels in your blood work).\n"
            "- Clarify how and when to take your medicines (e.g. Paracetamol safety).\n"
            "- Outline your surgical and allergy timelines.\n\n"
            "How can I assist you with your health records today?"
        )

@router.post("/chat", response_model=AIExplanationResponse)
def chat_assistant(request: AIQueryRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Consent validation
    consent = db.query(ConsentSetting).filter(ConsentSetting.user_id == current_user.id).first()
    context = request.context or ""
    
    if consent:
        if not consent.allow_ai_profile_read:
            # Mask out profile indicators in context
            context = "Consent Denied: AI has no permission to read patient profile metadata."
        if not consent.allow_ai_records_read:
            # Mask out records/history indicators in context
            if not consent.allow_ai_profile_read:
                context = "Consent Denied: AI has no permission to read patient profile or medical history/reports."
            else:
                context = f"Consent Denied: AI has no permission to read patient reports/history. User Profile context: {context.split('Allergies')[0] if 'Allergies' in context else context}"

    explanation = generate_gemini_content(request.prompt, context)
    
    # Save messages to database
    user_msg = AIChatMessage(user_id=current_user.id, message=request.prompt, is_user=True)
    ai_msg = AIChatMessage(user_id=current_user.id, message=explanation, is_user=False)
    db.add(user_msg)
    db.add(ai_msg)
    
    audit = AuditLog(user_id=current_user.id, action="AI_CHAT", details=f"AI Query: {request.prompt[:50]}...")
    db.add(audit)
    db.commit()
    
    return AIExplanationResponse(explanation=explanation)

@router.get("/chat-history", response_model=List[AIChatMessageResponse])
def get_chat_history(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    messages = db.query(AIChatMessage).filter(AIChatMessage.user_id == current_user.id).order_by(AIChatMessage.timestamp.asc()).all()
    # If empty, return a welcoming default message
    if not messages:
        # Save default message so it behaves like real history next time
        default_text = f"Hello, {current_user.profile.full_name if current_user.profile else 'Patient'}! I am your Aarogya Vault AI Health Assistant. How can I help you today? You can ask me to explain a report, outline a medicine schedule, or provide general wellness tips."
        welcome_msg = AIChatMessage(user_id=current_user.id, message=default_text, is_user=False)
        db.add(welcome_msg)
        db.commit()
        db.refresh(welcome_msg)
        return [welcome_msg]
    return messages

@router.delete("/chat-history")
def clear_chat_history(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db.query(AIChatMessage).filter(AIChatMessage.user_id == current_user.id).delete()
    
    audit = AuditLog(user_id=current_user.id, action="CLEAR_AI_HISTORY", details="Cleared AI Chat History logs")
    db.add(audit)
    db.commit()
    return {"status": "success", "message": "Chat history cleared successfully"}

@router.post("/explain-report/{report_id}", response_model=AIExplanationResponse)
def explain_report(report_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Respect general records consent settings
    consent = db.query(ConsentSetting).filter(ConsentSetting.user_id == current_user.id).first()
    if consent and not consent.allow_ai_records_read:
        return AIExplanationResponse(explanation="AI Explanation blocked: Consent for AI read-only access to medical records is disabled in Settings.")

    report = db.query(LabReport).filter(LabReport.id == report_id, LabReport.user_id == current_user.id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
        
    context = f"Report Title: {report.title}, Date: {report.date}, Type: {report.type}, Status: {report.status}."
    prompt = f"Provide a complete, readable explanation of my diagnostic report: {report.title}."
    
    explanation = generate_gemini_content(prompt, context)
    return AIExplanationResponse(explanation=explanation)

@router.get("/summary", response_model=AIExplanationResponse)
def get_patient_summary(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    consent = db.query(ConsentSetting).filter(ConsentSetting.user_id == current_user.id).first()
    if consent and (not consent.allow_ai_records_read or not consent.allow_ai_profile_read):
         return AIExplanationResponse(explanation="AI Summary blocked: Privacy settings block AI assistant from loading profile or clinical records details.")

    profile = db.query(Profile).filter(Profile.user_id == current_user.id).first()
    reports = db.query(LabReport).filter(LabReport.user_id == current_user.id).all()
    
    context = f"Patient Profile: Name={profile.full_name if profile else 'N/A'}, Blood={profile.blood_group if profile else 'N/A'}. Reports count: {len(reports)}."
    prompt = f"Generate a general health summary, risk analysis, and timeline."
    
    explanation = generate_gemini_content(prompt, context)
    return AIExplanationResponse(explanation=explanation)
