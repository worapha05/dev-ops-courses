"""API ตัวอย่างสำหรับ ECS Fargate / Cloud Run — อ่าน secret จาก env ที่ platform inject"""
import os

from fastapi import FastAPI

app = FastAPI(title="CCP Intermediate API")


@app.get("/healthz")
def healthz():
    """Health check endpoint."""
    return {"status": "ok"}


@app.get("/")
def root():
    """Root endpoint — แสดงว่ามี secret ถูก inject หรือไม่ (ห้ามคืนค่า secret)."""
    has_db = bool(os.getenv("DB_PASSWORD") or os.getenv("DATABASE_URL"))
    return {
        "service": os.getenv("SERVICE_NAME", "ccp-mid-api"),
        "environment": os.getenv("ENVIRONMENT", "unknown"),
        "db_secret_injected": has_db,
    }
