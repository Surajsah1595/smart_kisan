from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import joblib
import numpy as np
import requests
from bs4 import BeautifulSoup
print("Loading model...")

# Load model and encoders
model = joblib.load('crop_model.pkl')
soil_encoder = joblib.load('soil_encoder.pkl')
season_encoder = joblib.load('season_encoder.pkl')
crop_encoder = joblib.load('crop_encoder.pkl')

print("Model loaded successfully!")

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class CropRequest(BaseModel):
    soil_type: str
    season: str
    temp: float
    ph: float
    rainfall: float

@app.get("/")
def home():
    return {"message": "Smart Kisan API is running!"}

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.get("/api/market-prices")
def get_market_prices():
    # Fallback mock data to use if scraping fails or gets blocked by Cloudflare
    mock_data = [
    {"commodity": "Tomato Big(Nepali)", "unit": "Kg", "min_price": "60", "max_price": "70", "avg_price": "65"},
    {"commodity": "Tomato Small(Local)", "unit": "Kg", "min_price": "40", "max_price": "50", "avg_price": "45"},
    {"commodity": "Potato Red", "unit": "Kg", "min_price": "70", "max_price": "75", "avg_price": "73"},
    {"commodity": "Potato White", "unit": "Kg", "min_price": "50", "max_price": "60", "avg_price": "55"},
    {"commodity": "Onion Dry (Indian)", "unit": "Kg", "min_price": "90", "max_price": "100", "avg_price": "95"},
    {"commodity": "Onion Green", "unit": "Kg", "min_price": "60", "max_price": "80", "avg_price": "70"},
    {"commodity": "Brinjal Long", "unit": "Kg", "min_price": "60", "max_price": "70", "avg_price": "65"},
    {"commodity": "Brinjal Round", "unit": "Kg", "min_price": "65", "max_price": "75", "avg_price": "70"},
    {"commodity": "Cabbage(Local)", "unit": "Kg", "min_price": "50", "max_price": "60", "avg_price": "55"},
    {"commodity": "Cauli Local", "unit": "Kg", "min_price": "70", "max_price": "80", "avg_price": "75"},
    {"commodity": "Cauli Jyoti", "unit": "Kg", "min_price": "80", "max_price": "90", "avg_price": "85"},
    {"commodity": "Broccoli", "unit": "Kg", "min_price": "140", "max_price": "160", "avg_price": "150"},
    {"commodity": "Carrot(Local)", "unit": "Kg", "min_price": "110", "max_price": "120", "avg_price": "115"},
    {"commodity": "Raddish White(Local)", "unit": "Kg", "min_price": "40", "max_price": "50", "avg_price": "45"},
    {"commodity": "Raddish Red", "unit": "Kg", "min_price": "50", "max_price": "60", "avg_price": "55"},
    {"commodity": "Cow pea(Long)", "unit": "Kg", "min_price": "80", "max_price": "90", "avg_price": "85"},
    {"commodity": "Green Peas", "unit": "Kg", "min_price": "120", "max_price": "130", "avg_price": "125"},
    {"commodity": "French Bean(Local)", "unit": "Kg", "min_price": "70", "max_price": "80", "avg_price": "75"},
    {"commodity": "Soyabean Green", "unit": "Kg", "min_price": "80", "max_price": "90", "avg_price": "85"},
    {"commodity": "Bitter Gourd (Tite Karela)", "unit": "Kg", "min_price": "70", "max_price": "80", "avg_price": "75"},
    {"commodity": "Bottle Gourd (Lauka)", "unit": "Kg", "min_price": "50", "max_price": "60", "avg_price": "55"},
    {"commodity": "Pointed Gourd (Parwar)", "unit": "Kg", "min_price": "60", "max_price": "70", "avg_price": "65"},
    {"commodity": "Sponge Gourd (Ghiula)", "unit": "Kg", "min_price": "50", "max_price": "60", "avg_price": "55"},
    {"commodity": "Snake Gourd (Chichindo)", "unit": "Kg", "min_price": "40", "max_price": "50", "avg_price": "45"},
    {"commodity": "Pumpkin", "unit": "Kg", "min_price": "40", "max_price": "50", "avg_price": "45"},
    {"commodity": "Okra (Bhindi)", "unit": "Kg", "min_price": "60", "max_price": "75", "avg_price": "68"},
    {"commodity": "Chayote (Iskush)", "unit": "Kg", "min_price": "30", "max_price": "40", "avg_price": "35"},
    {"commodity": "Spinach Leaf (Palungo)", "unit": "Kg", "min_price": "80", "max_price": "100", "avg_price": "90"},
    {"commodity": "Mustard Leaf (Rayo)", "unit": "Kg", "min_price": "40", "max_price": "50", "avg_price": "45"},
    {"commodity": "Cress Leaf (Chamsur)", "unit": "Kg", "min_price": "90", "max_price": "110", "avg_price": "100"},
    {"commodity": "Fenugreek Leaf (Methi)", "unit": "Kg", "min_price": "90", "max_price": "110", "avg_price": "100"},
    {"commodity": "Coriander Green", "unit": "Kg", "min_price": "150", "max_price": "200", "avg_price": "175"},
    {"commodity": "Colocasia Leaf (Karkalo)", "unit": "Kg", "min_price": "50", "max_price": "60", "avg_price": "55"},
    {"commodity": "Garlic Dry Chinese", "unit": "Kg", "min_price": "250", "max_price": "260", "avg_price": "255"},
    {"commodity": "Garlic Dry Local", "unit": "Kg", "min_price": "200", "max_price": "220", "avg_price": "210"},
    {"commodity": "Ginger (Aduwa)", "unit": "Kg", "min_price": "120", "max_price": "150", "avg_price": "135"},
    {"commodity": "Chilli Green", "unit": "Kg", "min_price": "80", "max_price": "90", "avg_price": "85"},
    {"commodity": "Lemon", "unit": "Kg", "min_price": "140", "max_price": "160", "avg_price": "150"},
    {"commodity": "Apple(Jholey)", "unit": "Kg", "min_price": "250", "max_price": "280", "avg_price": "265"},
    {"commodity": "Apple(Fuji)", "unit": "Kg", "min_price": "300", "max_price": "350", "avg_price": "325"},
    {"commodity": "Banana", "unit": "Dozen", "min_price": "130", "max_price": "140", "avg_price": "135"},
    {"commodity": "Orange(Local)", "unit": "Kg", "min_price": "120", "max_price": "150", "avg_price": "135"},
    {"commodity": "Orange(Indian)", "unit": "Kg", "min_price": "160", "max_price": "180", "avg_price": "170"},
    {"commodity": "Mango(Malda)", "unit": "Kg", "min_price": "100", "max_price": "130", "avg_price": "115"},
    {"commodity": "Mango(Chauri)", "unit": "Kg", "min_price": "80", "max_price": "100", "avg_price": "90"},
    {"commodity": "Pomegranate (Anar)", "unit": "Kg", "min_price": "280", "max_price": "320", "avg_price": "300"},
    {"commodity": "Watermelon", "unit": "Kg", "min_price": "45", "max_price": "55", "avg_price": "50"},
    {"commodity": "Papaya(Local)", "unit": "Kg", "min_price": "60", "max_price": "70", "avg_price": "65"},
    {"commodity": "Grapes(Green)", "unit": "Kg", "min_price": "180", "max_price": "220", "avg_price": "200"},
    {"commodity": "Grapes(Black)", "unit": "Kg", "min_price": "250", "max_price": "300", "avg_price": "275"},
    {"commodity": "Pineapple", "unit": "Piece", "min_price": "120", "max_price": "150", "avg_price": "135"},
    {"commodity": "Litchi", "unit": "Kg", "min_price": "150", "max_price": "180", "avg_price": "165"},
    {"commodity": "Guava (Amba)", "unit": "Kg", "min_price": "60", "max_price": "80", "avg_price": "70"},
    {"commodity": "Sweet Lime (Mausam)", "unit": "Kg", "min_price": "140", "max_price": "160", "avg_price": "150"},
    {"commodity": "Mansuli Rice", "unit": "Quintal", "min_price": "6200", "max_price": "6500", "avg_price": "6350"},
    {"commodity": "Jeera Masino Rice", "unit": "Quintal", "min_price": "8200", "max_price": "8800", "avg_price": "8500"},
    {"commodity": "Basmati Rice Premium", "unit": "Quintal", "min_price": "14000", "max_price": "16000", "avg_price": "15000"},
    {"commodity": "Wheat (Gahun)", "unit": "Quintal", "min_price": "4200", "max_price": "4500", "avg_price": "4350"},
    {"commodity": "Maize Yellow (Makai)", "unit": "Quintal", "min_price": "3500", "max_price": "3800", "avg_price": "3650"},
    {"commodity": "Millet (Kodo)", "unit": "Quintal", "min_price": "5500", "max_price": "6000", "avg_price": "5750"},
    {"commodity": "Black Gram (Maas ko Daal)", "unit": "Kg", "min_price": "160", "max_price": "180", "avg_price": "170"},
    {"commodity": "Red Lentil (Musuro Daal)", "unit": "Kg", "min_price": "135", "max_price": "150", "avg_price": "142"},
    {"commodity": "Pigeon Pea (Rahar Daal)", "unit": "Kg", "min_price": "190", "max_price": "220", "avg_price": "205"},
    {"commodity": "Green Gram (Mugi Daal)", "unit": "Kg", "min_price": "150", "max_price": "170", "avg_price": "160"},
    {"commodity": "Chickpeas (Chana)", "unit": "Kg", "min_price": "110", "max_price": "130", "avg_price": "120"},
    {"commodity": "Mustard Seed (Tori)", "unit": "Quintal", "min_price": "9500", "max_price": "10500", "avg_price": "10000"}
]

    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
        }
        # Increased timeout and added verify=False to prevent SSL handshake crashes
        response = requests.get("https://kalimatimarket.gov.np/price", headers=headers, timeout=15, verify=False)
        
        if response.status_code != 200:
            print(f"Scraping returned status code: {response.status_code}")
            return {"status": "mock", "data": mock_data}
            
        soup = BeautifulSoup(response.content, 'html.parser')
        prices = []
        
        table = soup.find('table', {'class': 'table'}) or soup.find('table', id='commodityPriceBg')
        if not table:
            print("Table not found in HTML.")
            return {"status": "mock", "data": mock_data}
            
        tbody = table.find('tbody')
        if not tbody:
            print("Tbody not found in table.")
            return {"status": "mock", "data": mock_data}
            
        rows = tbody.find_all('tr')
        for row in rows:
            cols = row.find_all('td')
            if len(cols) >= 4:
                prices.append({
                    "commodity": cols[0].text.strip(),
                    "unit": cols[1].text.strip(),
                    "min_price": cols[2].text.strip().replace('Rs', '').strip(),
                    "max_price": cols[3].text.strip().replace('Rs', '').strip(),
                    "avg_price": cols[4].text.strip().replace('Rs', '').strip() if len(cols) > 4 else cols[3].text.strip().replace('Rs', '').strip()
                })
        
        if not prices:
            print("Prices array is empty after parsing.")
            return {"status": "mock", "data": mock_data}
            
        return {"status": "success", "data": prices}
        
    except Exception as e:
        print(f"Scraping exception safely caught: {e}")
        return {"status": "mock", "data": mock_data}
@app.post("/predict")
def predict(request: CropRequest):
    print(f"Received: soil={request.soil_type}, season={request.season}")
    
    # Validate Inputs to prevent nonsensical predictions
    if not (0 <= request.temp <= 55):
        raise HTTPException(status_code=400, detail="Temperature must be between 0 and 55 °C")
    if not (3.0 <= request.ph <= 10.0):
        raise HTTPException(status_code=400, detail="pH must be between 3.0 and 10.0")
    if not (10 <= request.rainfall <= 3500):
        raise HTTPException(status_code=400, detail="Rainfall must be between 10 and 3500 mm")
    
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
    
    # Create simulated ranges from the exact input (since model was trained on min/max ranges)
    temp_min = request.temp - 5.0
    temp_max = request.temp + 5.0
    ph_min = request.ph - 0.5
    ph_max = request.ph + 0.5
    rain_min = request.rainfall - 20.0
    rain_max = request.rainfall + 20.0

    # Make prediction
    features = np.array([[
        soil_num, season_num,
        temp_min, temp_max,
        ph_min, ph_max,
        rain_min, rain_max
    ]])
    
    prediction = model.predict(features)[0]
    crop_name = crop_encoder.inverse_transform([prediction])[0]
    
    print(f"Predicted: {crop_name}")
    
    return {"recommended_crop": crop_name}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)