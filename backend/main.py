# Flight Disruption Communications Generator - Backend
# FastAPI server with direct GGUF model loading via llama-cpp-python

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from llama_cpp import Llama
import os

app = FastAPI(
    title="Flight Disruption Communications Generator",
    description="AI-powered multi-channel communication generator for airline disruptions",
    version="1.0.0"
)

# CORS for frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
MODEL_PATH = os.getenv(
    "MODEL_PATH", 
    "/home/curtburk/Desktop/airline-demo/models/Qwen2.5-14B-Instruct-Q4_K_M.gguf"
)
N_GPU_LAYERS = int(os.getenv("N_GPU_LAYERS", "99"))  # Offload all layers to GPU
N_CTX = int(os.getenv("N_CTX", "4096"))  # Context window

# Global model instance (loaded once at startup)
llm = None


class DisruptionInput(BaseModel):
    flight_number: str
    origin: str
    destination: str
    original_time: str
    disruption_type: str  # "delay", "cancellation", "diversion"
    reason: str
    new_time: Optional[str] = "TBD"
    rebooking_options: Optional[str] = "Please see a gate agent for rebooking options"
    compensation_details: Optional[str] = "Standard compensation per DOT regulations"
    voucher_policy: Optional[str] = "Meal vouchers available at gate for delays over 2 hours"
    hotel_policy: Optional[str] = "Hotel accommodations provided for overnight cancellations"


class CommunicationsOutput(BaseModel):
    passenger_email: str
    sms_notification: str
    gate_agent_talking_points: str
    social_media_response: str


# System prompt shared across all channels
SYSTEM_PROMPT = """You are a communications specialist for a major airline. Your role is to draft clear, empathetic, and professional messages for passengers and staff during flight disruptions.

Guidelines:
- Lead with the essential information (what happened, what's next)
- Acknowledge inconvenience without over-apologizing
- Provide specific, actionable next steps
- Maintain brand voice: professional, warm, solution-oriented
- Never speculate on causes beyond what's provided
- Include relevant reference numbers and contact points where appropriate"""


def build_chat_prompt(system: str, user: str) -> str:
    """
    Format prompt for chat model using ChatML template.
    If gpt-oss-120b uses a different format, adjust this function.
    Common alternatives:
      - Llama: [INST] {system}\n{user} [/INST]
      - Alpaca: ### Instruction:\n{system}\n### Input:\n{user}\n### Response:\n
    """
    return f"""<|im_start|>system
{system}<|im_end|>
<|im_start|>user
{user}<|im_end|>
<|im_start|>assistant
"""


def generate_text(prompt: str, max_tokens: int = 500) -> str:
    """Generate text using the loaded model."""
    global llm
    if llm is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        output = llm(
            prompt,
            max_tokens=max_tokens,
            temperature=0.7,
            top_p=0.9,
            repeat_penalty=1.1,
            stop=["<|im_end|>", "<|endoftext|>", "<|im_start|>"],
        )
        return output["choices"][0]["text"].strip()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Generation error: {str(e)}")


@app.on_event("startup")
async def load_model():
    """Load the model at startup."""
    global llm
    print(f"""
╔══════════════════════════════════════════════════════════════╗
║     Loading Model...                                         ║
║     Path: {MODEL_PATH[:50]}...
║     GPU Layers: {N_GPU_LAYERS}                                           
║     Context: {N_CTX}                                            
║     This may take 1-2 minutes for a 120B model               ║
╚══════════════════════════════════════════════════════════════╝
    """)
    
    if not os.path.exists(MODEL_PATH):
        print(f"❌ Error: Model file not found at {MODEL_PATH}")
        print("Please download the model first or set MODEL_PATH environment variable.")
        return
    
    try:
        llm = Llama(
            model_path=MODEL_PATH,
            n_gpu_layers=N_GPU_LAYERS,
            n_ctx=N_CTX,
            flash_attn=True,
            verbose=True,
        )
        print("✅ Model loaded successfully!")
    except Exception as e:
        print(f"❌ Error loading model: {e}")
        llm = None


@app.post("/api/generate-communications", response_model=CommunicationsOutput)
async def generate_communications(data: DisruptionInput):
    """Generate multi-channel communications for a flight disruption."""
    
    if llm is None:
        raise HTTPException(status_code=503, detail="Model not loaded. Check server logs.")
    
    try:
        # === PASSENGER EMAIL ===
        email_prompt = f"""Generate a passenger notification email for the following flight disruption:

Flight: {data.flight_number}
Route: {data.origin} → {data.destination}
Original Departure: {data.original_time}
Disruption Type: {data.disruption_type.upper()}
Reason: {data.reason}
New Departure: {data.new_time}
Rebooking Options: {data.rebooking_options}
Compensation: {data.compensation_details}

Write a complete email including:
1. A clear subject line
2. Greeting
3. Explanation of the situation
4. What happens next (rebooking options as clear bullet points)
5. Compensation/amenities available
6. Contact information for further assistance
7. Professional closing

Tone: Apologetic but action-focused. Empathetic but efficient."""

        email = generate_text(
            build_chat_prompt(SYSTEM_PROMPT, email_prompt), 
            max_tokens=400
        )

        # === SMS NOTIFICATION ===
        sms_prompt = f"""Generate a brief SMS/text notification (MUST be under 160 characters) for:

Flight: {data.flight_number}
Route: {data.origin}→{data.destination}
Status: {data.disruption_type.upper()}
New Time: {data.new_time}

Requirements:
- Under 160 characters total
- Include flight number
- State the disruption clearly
- Include one action item
- End with where to get more info (app or counter)

Just output the SMS text, nothing else."""

        sms = generate_text(
            build_chat_prompt(SYSTEM_PROMPT, sms_prompt), 
            max_tokens=100
        )
        # Truncate if model went over
        if len(sms) > 160:
            sms = sms[:157] + "..."

        # === GATE AGENT TALKING POINTS ===
        gate_prompt = f"""Generate talking points for gate agents handling flight {data.flight_number}:

Flight: {data.flight_number}
Route: {data.origin} → {data.destination}
Disruption: {data.disruption_type.upper()}
Reason: {data.reason}
New Departure: {data.new_time}
Rebooking Options: {data.rebooking_options}
Meal Vouchers: {data.voucher_policy}
Hotel: {data.hotel_policy}

Provide:
1. **PA ANNOUNCEMENT** - Script to read over intercom (2-3 sentences)
2. **KEY FACTS** - Bullet points of essential information
3. **ANTICIPATED QUESTIONS** - Top 5 passenger questions with suggested answers
4. **ESCALATION** - When and how to escalate angry passengers

Format clearly with headers."""

        gate_points = generate_text(
            build_chat_prompt(SYSTEM_PROMPT, gate_prompt), 
            max_tokens=450
        )

        # === SOCIAL MEDIA RESPONSE ===
        social_prompt = f"""Generate a Twitter/X response template (MUST be under 280 characters) for passengers complaining about:

Flight: {data.flight_number}
Issue: {data.disruption_type}
Route: {data.origin} to {data.destination}

Requirements:
- Under 280 characters
- Acknowledge their frustration briefly
- Provide current status in few words
- Direct them to DM for personal help
- Professional but human tone
- Include ^[initials] at end (use ^TM)

Just output the tweet text, nothing else."""

        social = generate_text(
            build_chat_prompt(SYSTEM_PROMPT, social_prompt), 
            max_tokens=150
        )
        # Truncate if model went over
        if len(social) > 280:
            social = social[:277] + "..."

        return CommunicationsOutput(
            passenger_email=email,
            sms_notification=sms,
            gate_agent_talking_points=gate_points,
            social_media_response=social
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Generation error: {str(e)}")


@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "ok" if llm is not None else "model_not_loaded",
        "model_path": MODEL_PATH,
        "model_loaded": llm is not None,
    }


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "service": "Flight Disruption Communications Generator",
        "status": "running",
        "model_loaded": llm is not None
    }


if __name__ == "__main__":
    import uvicorn
    print("""
╔══════════════════════════════════════════════════════════════╗
║     Flight Disruption Communications Generator               ║
║     ─────────────────────────────────────────────            ║
║     Starting server on http://0.0.0.0:8000                   ║
║                                                              ║
║     Endpoints:                                               ║
║       POST /api/generate-communications                      ║
║       GET  /api/health                                       ║
╚══════════════════════════════════════════════════════════════╝
    """)
    uvicorn.run(app, host="0.0.0.0", port=8000)
