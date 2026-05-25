import pandas as pd
import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder

print("Loading dataset...")

# Load dataset
df = pd.read_csv('crop_dataset.csv')

print(f"Dataset loaded successfully!")
print(f"Total rows: {len(df)}")
print(f"Total columns: {len(df.columns)}")

# Encode categorical columns
soil_encoder = LabelEncoder()
season_encoder = LabelEncoder()
crop_encoder = LabelEncoder()
water_need_encoder = LabelEncoder()
difficulty_encoder = LabelEncoder()

df['soil_encoded'] = soil_encoder.fit_transform(df['soil_type'])
df['season_encoded'] = season_encoder.fit_transform(df['season'])
df['crop_encoded'] = crop_encoder.fit_transform(df['crop_name'])
df['water_need_encoded'] = water_need_encoder.fit_transform(df['water_need'])
df['difficulty_encoded'] = difficulty_encoder.fit_transform(df['difficulty_level'])

# Features for training - using all available numeric columns
features = [
    'soil_encoded', 'season_encoded', 'water_need_encoded', 'difficulty_encoded',
    'temp_min', 'temp_max', 'ph_min', 'ph_max', 
    'rainfall_min', 'rainfall_max', 'duration_days',
    'humidity_min', 'humidity_max', 'altitude_min', 'altitude_max',
    'fertilizer_n', 'fertilizer_p', 'fertilizer_k',
    'yield_ton_per_ha', 'profit_usd_per_ha'
]

# Keep only features that exist in the dataframe
available_features = [f for f in features if f in df.columns]
print(f"Using {len(available_features)} features for training")

X = df[available_features]
y = df['crop_encoded']

# Train model
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X, y)

# Save everything
joblib.dump(model, 'crop_model.pkl')
joblib.dump(soil_encoder, 'soil_encoder.pkl')
joblib.dump(season_encoder, 'season_encoder.pkl')
joblib.dump(crop_encoder, 'crop_encoder.pkl')
joblib.dump(water_need_encoder, 'water_need_encoder.pkl')
joblib.dump(difficulty_encoder, 'difficulty_encoder.pkl')

print("Model saved successfully!")
print(f"Training accuracy: {model.score(X, y) * 100:.2f}%")