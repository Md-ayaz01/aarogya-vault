import logging
import google.generativeai as genai
from typing import Optional
from app.core.config import settings

logger = logging.getLogger("aarogya_vault_ai")

# Configure Gemini API client
if settings.GEMINI_API_KEY:
    try:
        genai.configure(api_key=settings.GEMINI_API_KEY)
        logger.info("Google Gemini API client initialized successfully.")
    except Exception as e:
        logger.error(f"Failed to configure Google Gemini API client: {e}")

class AIService:
    def __init__(self):
        self.model_name = "gemini-1.5-flash"
        self.system_instruction = (
            "You are Aarogya Vault's secure AI Health Assistant. "
            "Your role is to explain medical parameters, lab reports, imaging scans, and prescriptions "
            "in plain, accessible, and structured terms. Focus on diet, lifestyle, and dosage safety. "
            "\n\n"
            "SAFETY CONSTRAINTS:\n"
            "- ALWAYS preface clinical details by stating that your insights are for educational purposes only. "
            "- YOU MUST NEVER DIAGNOSE DISEASES under any circumstances.\n"
            "- YOU MUST NEVER PRESCRIBE MEDICATIONS or adjust doses.\n"
            "- ALWAYS explicitly recommend that the patient consult licensed healthcare professionals for diagnosis and treatment changes."
        )

    def generate_health_insight(self, prompt: str, context: Optional[str] = None) -> str:
        """Generates patient insights using Google Gemini 1.5 Flash API with strict safety bounds."""
        disclaimer = (
            "**Medical Disclaimer**: Aarogya Vault AI Health Assistant provides educational insights only. "
            "It does not diagnose conditions, prescribe drugs, or replace professional medical advice. "
            "Please consult a qualified licensed healthcare provider before making any clinical decisions.\n\n"
        )
        
        if not settings.GEMINI_API_KEY:
            logger.warning("GEMINI_API_KEY is not configured. Falling back to sandbox responses.")
            return disclaimer + self._get_sandbox_response(prompt, context)
            
        try:
            model = genai.GenerativeModel(
                model_name=self.model_name,
                system_instruction=self.system_instruction
            )
            full_prompt = f"Patient Context Info:\n{context or 'No context available.'}\n\nQuery:\n{prompt}"
            response = model.generate_content(full_prompt)
            # Prepend standard disclaimer to all outputs
            return disclaimer + response.text
        except Exception as e:
            logger.error(f"Gemini API execution error: {e}. Falling back to sandbox.")
            return disclaimer + self._get_sandbox_response(prompt, context)

    def _get_sandbox_response(self, prompt: str, context: Optional[str] = None) -> str:
        """Fallback sandbox response engine when offline or Gemini API is unconfigured."""
        prompt_lower = prompt.lower()
        
        if "blood report" in prompt_lower or "explain my report" in prompt_lower or "glucose" in prompt_lower:
            return (
                "### AI Lab Report Analysis (Sandbox)\n\n"
                "Based on the fasting glucose parameters in your record:\n"
                "- **Fasting Glucose**: 98 mg/dL (Borderline normal: 70-99 mg/dL). This is within reference values but near pre-diabetic thresholds.\n"
                "- **LDL Cholesterol**: 115 mg/dL (Elevated). Optimal range is under 100 mg/dL.\n\n"
                "**Lifestyle Recommendations**:\n"
                "- Limit refined sugars and processed carbohydrate foods.\n"
                "- Engage in at least 150 minutes of moderate aerobic exercise weekly.\n"
                "- Consult your primary physician for a lipid panel repeat test in 3-6 months."
            )
        elif "mri" in prompt_lower or "brain" in prompt_lower:
            return (
                "### AI Brain MRI Summary (Sandbox)\n\n"
                "Based on your imaging scan details:\n"
                "- **Scan Findings**: Cerebral hemispheres, cerebellum, and brainstem appear structurally normal. No evidence of masses or acute hemorrhage.\n"
                "- **Clinical Insight**: Bony structures are intact. Brain ventricles are normal.\n\n"
                "Please verify these structural interpretations with your neurologist."
            )
        elif "paracetamol" in prompt_lower or "azithromycin" in prompt_lower or "cetirizine" in prompt_lower:
            return (
                "### AI Medication Analysis (Sandbox)\n\n"
                "Here is the educational breakdown of the medication items:\n"
                "1. **Paracetamol 650mg** (Analgesic): Used for relieving fever and mild pain. Maximum dose is 4g per day to prevent liver toxicity.\n"
                "2. **Azithromycin 500mg** (Macrolide Antibiotic): Used for treating bacterial infections. Must complete the full course to prevent antibiotic resistance.\n"
                "3. **Cetirizine 10mg** (Antihistamine): Relieves allergic rhinitis. Commonly taken at night due to mild sedative effects."
            )
        else:
            return (
                "### Aarogya Vault AI Health Assistant (Sandbox)\n\n"
                "Hello! I am your secure clinical helper. I can explain lab parameters, medication directions, and summaries of reports in plain terms.\n\n"
                "How can I assist you with your health records today?"
            )

ai_service = AIService()
