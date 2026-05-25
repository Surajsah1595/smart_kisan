@echo off
echo Starting Smart Kisan ML Backend Server...
cd ml_backend
call ..\.venv\Scripts\activate.bat
echo Updating IP in Flutter app...
python update_ip.py
uvicorn app:app --host 0.0.0.0 --port 8000
pause
