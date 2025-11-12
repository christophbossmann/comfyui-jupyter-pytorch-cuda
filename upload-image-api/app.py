from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import FileResponse
from datetime import datetime, timedelta
from pathlib import Path
import shutil
import threading
import time
import os
import logging

app = FastAPI(title="ComfyUI File API")

# --- LOGGING CONFIGURATION ---
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("uvicorn")

# --- CONFIGURATION (env-aware) ---
INPUT_DIR = Path(os.getenv("COMFY_INPUT_DIR", "/app/ComfyUI/input"))
OUTPUT_DIR = Path(os.getenv("COMFY_OUTPUT_DIR", "/app/ComfyUI/output"))

# Lifetime in minutes (default 120 = 2 hours)
FILE_LIFETIME_MINUTES = float(os.getenv("FILE_LIFETIME_MINUTES", "120"))
FILE_LIFETIME = timedelta(minutes=FILE_LIFETIME_MINUTES)

# Files that should never be deleted (case-insensitive)
KEEP_FILES = [
    "example.png"
]

# Create directories if needed
INPUT_DIR.mkdir(parents=True, exist_ok=True)
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# --- STARTUP LOGGING ---
@app.on_event("startup")
def startup_event():
    logger.info("ComfyUI File API started with configuration:")
    logger.info(f"INPUT_DIR: {INPUT_DIR}")
    logger.info(f"OUTPUT_DIR: {OUTPUT_DIR}")
    logger.info(f"FILE_LIFETIME_MINUTES: {FILE_LIFETIME_MINUTES}")
    logger.info(f"KEEP_FILES: {KEEP_FILES}")

# --- DEFAULT ENDPOINT ---
@app.get("/")
def get_default():
    return {"message": "Upload-image-api is started and working"}

# --- INFO ENDPOINT ---
@app.get("/info")
def get_info():
    return {
        "input_dir": str(INPUT_DIR),
        "output_dir": str(OUTPUT_DIR),
        "file_lifetime_minutes": FILE_LIFETIME_MINUTES,
        "keep_files": KEEP_FILES,
    }

# --- UPLOAD ENDPOINT ---
@app.post("/upload")
def upload_image(file: UploadFile = File(...)):
    ext = Path(file.filename).suffix.lower()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    filename = f"{timestamp}{ext}"
    target_path = INPUT_DIR / filename

    with open(target_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    logger.info(f"Uploaded file saved as: {filename}")
    return {"filename": filename}

# --- SERVE UPLOADED FILES ---
@app.get("/input/{filename}")
def get_uploaded_file(filename: str):
    file_path = INPUT_DIR / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(file_path)

# --- SERVE GENERATED FILES ---
@app.get("/output/{filename}")
def get_generated_file(filename: str):
    file_path = OUTPUT_DIR / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Generated file not found")
    return FileResponse(file_path)

# --- FUN TEAPOT ENDPOINT ---
@app.get("/teapot")
def im_a_teapot():
    raise HTTPException(status_code=418, detail="418: 🫖 I'm a teapot. I cannot brew coffee, only tea!")

# --- BACKGROUND CLEANUP THREAD ---
def cleanup_old_files():
    while True:
        now = datetime.now()
        for directory in [INPUT_DIR, OUTPUT_DIR]:
            for file in directory.iterdir():
                try:
                    if file.is_file():
                        filename = file.name.lower()
                        # Skip if it's in KEEP_FILES
                        if filename in [f.lower() for f in KEEP_FILES]:
                            continue
                        mtime = datetime.fromtimestamp(file.stat().st_mtime)
                        if now - mtime > FILE_LIFETIME:
                            file.unlink()
                            logger.info(f"🧹 Deleted old file: {file}")
                except Exception as e:
                    logger.warning(f"Cleanup failed for {file}: {e}")
        time.sleep(600)  # every 10 minutes

threading.Thread(target=cleanup_old_files, daemon=True).start()