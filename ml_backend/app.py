from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import numpy as np

print("Loading model...")

# Load model and encoders
model = joblib.load('crop_model.pkl')
soil_encoder = joblib.load('soil_encoder.pkl')
season_encoder = joblib.load('season_encoder.pkl')
crop_encoder = joblib.load('crop_encoder.pkl')

print("Model loaded successfully!")

app = FastAPI()

class CropRequest(BaseModel):
    soil_type: str
    season: str
    temp: float
    ph: float
    rainfall: float

@app.get("/")
def home():
    return {"message": "Smart Kisan API is running!"}

@app.post("/predict")
def predict(request: CropRequest):
    print(f"Received: soil={request.soil_type}, season={request.season}")
    
    # 1. Clean and Map Soil
    soil_lower = request.soil_type.lower()
    clean_soil = "Loamy" # default
    if "sand" in soil_lower: clean_soil = "Sandy"
    elif "clay" in soil_lower: clean_soil = "Clay"
    elif "black" in soil_lower: clean_soil = "Black"
    elif "silt" in soil_lower: clean_soil = "Silty"
    elif "loam" in soil_lower: clean_soil = "Loamy"
    
    # 2. Clean and Map Season
    season_lower = request.season.lower()
    clean_season = "Summer" # default
    if "monsoon" in season_lower: clean_season = "Monsoon"
    elif "winter" in season_lower: clean_season = "Winter"
    elif "summer" in season_lower: clean_season = "Summer"
    
    # Convert words to numbers safely
    soil_num = soil_encoder.transform([clean_soil])[0]
    season_num = season_encoder.transform([clean_season])[0]
    
    # Make prediction
    features = np.array([[
        soil_num, season_num,
        request.temp, request.temp,
        request.ph, request.ph,
        request.rainfall, request.rainfall
    ]])
    
    prediction = model.predict(features)[0]
    crop_name = crop_encoder.inverse_transform([prediction])[0]
    
    print(f"Predicted: {crop_name}")
    
    return {"recommended_crop": crop_name}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)