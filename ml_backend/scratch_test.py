import pandas as pd
import joblib
import numpy as np

model = joblib.load('crop_model.pkl')
soil_encoder = joblib.load('soil_encoder.pkl')
season_encoder = joblib.load('season_encoder.pkl')
crop_encoder = joblib.load('crop_encoder.pkl')

df = pd.read_csv('crop_dataset.csv')

def test_crop(target_crop):
    rows = df[df['crop_name'] == target_crop]
    for _, row in rows.iterrows():
        try:
            s = row['soil_type'].lower()
            cs = 'Loamy'
            if 'sand' in s: cs = 'Sandy'
            elif 'clay' in s: cs = 'Clay'
            elif 'black' in s: cs = 'Black'
            elif 'silt' in s: cs = 'Silty'
            elif 'loam' in s: cs = 'Loamy'
            
            se = row['season'].lower()
            cse = 'Summer'
            if 'monsoon' in se: cse = 'Monsoon'
            elif 'winter' in se: cse = 'Winter'
            elif 'summer' in se: cse = 'Summer'
            
            soil_n = soil_encoder.transform([cs])[0]
            season_n = season_encoder.transform([cse])[0]
            
            # Midpoints
            temp_mid = (row['temp_min'] + row['temp_max']) / 2
            ph_mid = (row['ph_min'] + row['ph_max']) / 2
            rain_mid = (row['rainfall_min'] + row['rainfall_max']) / 2
            
            features = np.array([[soil_n, season_n, temp_mid-5, temp_mid+5, ph_mid-0.5, ph_mid+0.5, rain_mid-20, rain_mid+20]])
            pred_n = model.predict(features)[0]
            pred_name = crop_encoder.inverse_transform([pred_n])[0]
            if pred_name == target_crop:
                print(f"✅ EXACT MATCH For {target_crop} -> Soil: {cs}, Season: {cse}, Temp: {temp_mid}, pH: {ph_mid}, Rainfall: {rain_mid}")
                return
            else:
                pass
        except Exception as e:
            pass
    print(f"❌ No exact bounds match found for {target_crop} (Model strongly overlaps with something else)")

test_crop('Wheat (Winter)')
test_crop('Rice (Aus)')
test_crop('Groundnut')
test_crop('Buckwheat')
test_crop('Barley')
