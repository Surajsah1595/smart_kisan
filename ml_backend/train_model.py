import pandas as pd
import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder

print("Starting training...")

# Load dataset
df = pd.read_csv('crop_dataset.csv')

print(f"Dataset loaded! Found {len(df)} crops")

# Encode categorical columns
soil_encoder = LabelEncoder()
season_encoder = LabelEncoder()
crop_encoder = LabelEncoder()

df['soil_encoded'] = soil_encoder.fit_transform(df['soil_type'])
df['season_encoded'] = season_encoder.fit_transform(df['season'])
df['crop_encoded'] = crop_encoder.fit_transform(df['crop_name'])

# Features and target
features = ['soil_encoded', 'season_encoded', 'temp_min', 'temp_max', 
            'ph_min', 'ph_max', 'rainfall_min', 'rainfall_max']

X = df[features]
y = df['crop_encoded']

# Train model
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X, y)

# Save everything
joblib.dump(model, 'crop_model.pkl')
joblib.dump(soil_encoder, 'soil_encoder.pkl')
joblib.dump(season_encoder, 'season_encoder.pkl')
joblib.dump(crop_encoder, 'crop_encoder.pkl')

print("SUCCESS! Model saved as crop_model.pkl")
print("Files created successfully!")