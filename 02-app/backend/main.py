from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Iac DX Validator - Backend API") 

# Autorise le Frontend à communiquer avec cette API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # En prod, on mettrait l'IP exacte du Frontend
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Instrumentator().instrument(app).expose(app)

@app.get("/")
def read_root():
    return {
        "message": "Hello depuis le Subnet Privé !", 
        "status": "success"
    }

@app.get("/health")
def healt_check():
    return {"status": "healthy"}

