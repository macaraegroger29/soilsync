import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
import joblib
import os
from django.conf import settings
from .models import SoilData, CropRecommendation

class CropRecommendationService:
    """
    AI-powered crop recommendation service using machine learning
    """
    
    def __init__(self):
        self.model_path = os.path.join(settings.BASE_DIR, 'lib', 'models', 'crop_recommendation_model.pkl')
        self.scaler_path = os.path.join(settings.BASE_DIR, 'lib', 'models', 'crop_scaler.pkl')
        self.model = None
        self.scaler = None
        self.load_model()
    
    def load_model(self):
        """Load the trained ML model and scaler"""
        try:
            if os.path.exists(self.model_path):
                self.model = joblib.load(self.model_path)
            if os.path.exists(self.scaler_path):
                self.scaler = joblib.load(self.scaler_path)
        except Exception as e:
            print(f"Error loading model: {e}")
            self.train_model()
    
    def train_model(self):
        """Train the crop recommendation model with sample data"""
        # Sample training data - in production, this would be loaded from a dataset
        training_data = {
            'N': [90, 85, 60, 50, 75, 65, 70, 80, 95, 70],
            'P': [42, 58, 25, 35, 40, 48, 35, 60, 45, 50],
            'K': [43, 41, 25, 40, 42, 45, 50, 55, 60, 48],
            'temperature': [25, 28, 30, 32, 22, 24, 26, 29, 27, 25],
            'humidity': [80, 70, 65, 60, 85, 75, 78, 72, 75, 80],
            'ph': [6.5, 7.0, 6.8, 7.2, 6.0, 6.5, 7.0, 6.8, 7.1, 6.9],
            'rainfall': [200, 220, 180, 250, 190, 210, 230, 240, 215, 205],
            'label': ['Rice', 'Wheat', 'Maize', 'Sugarcane', 'Potato', 'Tomato', 'Cotton', 'Soybean', 'Groundnut', 'Barley']
        }
        
        df = pd.DataFrame(training_data)
        
        # Features and target
        X = df[['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']]
        y = df['label']
        
        # Scale features
        self.scaler = StandardScaler()
        X_scaled = self.scaler.fit_transform(X)
        
        # Train model
        self.model = RandomForestClassifier(n_estimators=100, random_state=42)
        self.model.fit(X_scaled, y)
        
        # Save model
        os.makedirs(os.path.dirname(self.model_path), exist_ok=True)
        joblib.dump(self.model, self.model_path)
        joblib.dump(self.scaler, self.scaler_path)
    
    def predict_crop(self, soil_data):
        """Predict the best crop for given soil conditions"""
        if not self.model or not self.scaler:
            return None
        
        # Prepare features
        features = np.array([[
            soil_data.nitrogen,
            soil_data.phosphorus,
            soil_data.potassium,
            soil_data.temperature,
            soil_data.moisture,
            soil_data.ph_level,
            soil_data.rainfall
        ]])
        
        # Scale features
        features_scaled = self.scaler.transform(features)
        
        # Get prediction and probability
        prediction = self.model.predict(features_scaled)[0]
        probabilities = self.model.predict_proba(features_scaled)[0]
        
        # Get confidence score
        max_prob = max(probabilities)
        
        return {
            'crop': prediction,
            'confidence': max_prob * 100
        }
    
    def generate_recommendations(self, soil_data_id):
        """Generate crop recommendations for a specific soil data entry"""
        try:
            soil_data = SoilData.objects.get(id=soil_data_id)
            
            # Check if recommendation already exists
            existing = CropRecommendation.objects.filter(
                soil_data=soil_data
            ).first()
            
            if existing:
                return existing
            
            # Generate new recommendation
            result = self.predict_crop(soil_data)
            
            if result:
                recommendation = CropRecommendation.objects.create(
                    soil_data=soil_data,
                    crop_name=result['crop'],
                    suitability_score=result['confidence']
                )
                
                return recommendation
            
        except SoilData.DoesNotExist:
            return None
    
    def get_top_recommendations(self, soil_data, top_n=3):
        """Get top N crop recommendations for given soil conditions"""
        if not self.model or not self.scaler:
            return []
        
        features = np.array([[
            soil_data.nitrogen,
            soil_data.phosphorus,
            soil_data.potassium,
            soil_data.temperature,
            soil_data.moisture,
            soil_data.ph_level,
            soil_data.rainfall
        ]])
        
        features_scaled = self.scaler.transform(features)
        
        # Get probabilities for all classes
        probabilities = self.model.predict_proba(features_scaled)[0]
        classes = self.model.classes_
        
        # Create list of (crop, probability) pairs
        recommendations = [
            {'crop': crop, 'confidence': prob * 100}
            for crop, prob in zip(classes, probabilities)
        ]
        
        # Sort by confidence and return top N
        recommendations.sort(key=lambda x: x['confidence'], reverse=True)
        return recommendations[:top_n]
