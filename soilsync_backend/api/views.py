from django.contrib.auth import get_user_model
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework.views import APIView
from django.contrib.auth.password_validation import validate_password
import logging
import requests
import json
from .serializers import CustomUserSerializer, SoilDataSerializer
from .models import SoilData, Dataset
import joblib
import pandas as pd
import numpy as np
import os
from django.conf import settings
from django.core.paginator import Paginator
from rest_framework.renderers import JSONRenderer

logger = logging.getLogger(__name__)
User = get_user_model()

# Load the model
MODEL_PATH = os.path.join(settings.BASE_DIR, 'lib', 'models', 'RandomForest.pkl')
try:
    model = joblib.load(MODEL_PATH)
    logger.info(f"Successfully loaded model from {MODEL_PATH}")
except Exception as e:
    logger.error(f"Error loading model from {MODEL_PATH}: {str(e)}")
    # Try alternative path
    try:
        MODEL_PATH = os.path.join(settings.BASE_DIR.parent, 'lib', 'models', 'RandomForest.pkl')
        model = joblib.load(MODEL_PATH)
        logger.info(f"Successfully loaded model from alternative path: {MODEL_PATH}")
    except Exception as e2:
        logger.error(f"Error loading model from alternative path: {str(e2)}")
        model = None

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role
        return token

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

    def post(self, request, *args, **kwargs):
        logger.info("=== Login Attempt ===")
        logger.info(f"Username: {request.data.get('username')}")
        logger.info(f"Request data: {request.data}")
        logger.info(f"Request headers: {request.headers}")
        logger.info(f"Request method: {request.method}")
        logger.info(f"Request path: {request.path}")

        try:
            response = super().post(request, *args, **kwargs)
            logger.info(f"Login response status: {response.status_code}")
            logger.info(f"Login response data: {response.data}")

            if response.status_code == 200:
                try:
                    user = User.objects.get(username=request.data["username"])
                    logger.info(f"User found: {user.username}")
                    logger.info(f"User is superuser: {user.is_superuser}")
                    logger.info(f"User role: {user.role}")

                    # Always set role to admin for superusers
                    if user.is_superuser:
                        response.data["role"] = "admin"
                        logger.info("Setting role to admin for superuser")
                    else:
                        response.data["role"] = getattr(user, 'role', 'user')
                        logger.info(f"Setting role to {response.data['role']}")

                    # Ensure the role is included in the response
                    if 'role' not in response.data:
                        response.data['role'] = 'user'
                        logger.info("No role found, defaulting to 'user'")
                except User.DoesNotExist:
                    logger.error(f"User not found: {request.data['username']}")
                    return Response({"error": "User not found"}, status=status.HTTP_400_BAD_REQUEST)
            else:
                logger.error(f"Login failed with status {response.status_code}: {response.data}")
            return response
        except Exception as e:
            logger.error(f"Unexpected error during login: {str(e)}")
            return Response(
                {"error": "An unexpected error occurred"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class RegisterView(APIView):
    permission_classes = []  # Allow unauthenticated access
    
    def post(self, request):
        try:
            serializer = CustomUserSerializer(data=request.data)
            if serializer.is_valid():
                serializer.save()
                logger.info(f"User {request.data.get('username')} created successfully")
                return Response(
                    {"message": "User created successfully"},
                    status=status.HTTP_201_CREATED
                )
            else:
                logger.error(f"Validation error: {serializer.errors}")
                return Response(
                    {"error": serializer.errors},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except Exception as e:
            logger.error(f"Unexpected error in registration: {str(e)}")
            return Response(
                {"error": str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

class PredictSoilView(APIView):
    def post(self, request):
        try:
            if model is None:
                return Response(
                    {"error": "Model not loaded. Please check the model path and try again."},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

            serializer = SoilDataSerializer(data=request.data)
            if serializer.is_valid():
                # Prepare data for prediction
                data = serializer.validated_data
                input_data = np.array([[
                    data['nitrogen'],
                    data['phosphorus'],
                    data['potassium'],
                    data['temperature'],
                    data['humidity'],
                    data['ph'],
                    data['rainfall']
                ]])

                # Make prediction
                prediction = model.predict(input_data)[0]
                logger.info(f"Made prediction: {prediction} for input: {input_data}")

                # Get top N probable crops using predict_proba
                if hasattr(model, 'predict_proba'):
                    proba = model.predict_proba(input_data)[0]
                    class_labels = model.classes_
                    N = 5
                    top_indices = proba.argsort()[-N:][::-1]
                    top_crops = [
                        {"label": str(class_labels[i]), "confidence": float(proba[i])}
                        for i in top_indices
                    ]
                else:
                    top_crops = [{"label": str(prediction), "confidence": 1.0}]

                # Save the data with prediction
                soil_data = serializer.save(
                    user=request.user,
                    prediction=prediction
                )

                # Get similar cases from the dataset (legacy, can be removed later)
                similar_cases = Dataset.objects.filter(
                    label=prediction
                ).order_by('?')[:5]  # Get 5 random similar cases

                similar_cases_data = [{
                    'nitrogen': case.nitrogen,
                    'phosphorus': case.phosphorus,
                    'potassium': case.potassium,
                    'temperature': case.temperature,
                    'humidity': case.humidity,
                    'ph': case.ph,
                    'rainfall': case.rainfall,
                    'label': case.label
                } for case in similar_cases]

                return Response({
                    "message": "Prediction successful",
                    "prediction": prediction,
                    "data": SoilDataSerializer(soil_data).data,
                    "top_crops": top_crops,
                    "similar_cases": similar_cases_data
                }, status=status.HTTP_201_CREATED)
            else:
                return Response(
                    {"error": serializer.errors},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except Exception as e:
            logger.error(f"Error in prediction: {str(e)}")
            return Response(
                {"error": str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

    def get(self, request):
        try:
            soil_data = SoilData.objects.filter(user=request.user).order_by('-created_at')
            serializer = SoilDataSerializer(soil_data, many=True)
            return Response(serializer.data)
        except Exception as e:
            logger.error(f"Error fetching soil data: {str(e)}")
            return Response(
                {"error": str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

class ListUsersView(APIView):
    def get(self, request):
        try:
            # Check if user is admin
            if not request.user.is_authenticated or request.user.role != 'admin':
                return Response(
                    {"error": "Only admin users can view all accounts"},
                    status=status.HTTP_403_FORBIDDEN
                )

            users = User.objects.all()
            user_data = []
            for user in users:
                user_data.append({
                    'id': user.id,
                    'username': user.username,
                    'email': user.email,
                    'role': user.role,
                    'date_joined': user.date_joined,
                    'last_login': user.last_login,
                    'is_active': user.is_active,
                    'is_superuser': user.is_superuser
                })
            
            return Response({
                "total_users": len(user_data),
                "users": user_data
            })
        except Exception as e:
            logger.error(f"Error listing users: {str(e)}")
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ListDatasetView(APIView):
    def get(self, request):
        try:
            # Check if user is admin
            if not request.user.is_authenticated or request.user.role != 'admin':
                return Response(
                    {"error": "Only admin users can view the dataset"},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Get page number from query params, default to 1
            page = request.GET.get('page', 1)
            try:
                page = int(page)
            except ValueError:
                page = 1

            # Get all dataset entries
            dataset = Dataset.objects.all().order_by('id')
            
            # Paginate results - 50 items per page
            paginator = Paginator(dataset, 50)
            current_page = paginator.get_page(page)

            # Prepare the data
            dataset_data = []
            for entry in current_page:
                dataset_data.append({
                    'id': entry.id,
                    'nitrogen': entry.nitrogen,
                    'phosphorus': entry.phosphorus,
                    'potassium': entry.potassium,
                    'temperature': entry.temperature,
                    'humidity': entry.humidity,
                    'ph': entry.ph,
                    'rainfall': entry.rainfall,
                    'label': entry.label,
                })
            
            return Response({
                "total_entries": paginator.count,
                "total_pages": paginator.num_pages,
                "current_page": page,
                "has_next": current_page.has_next(),
                "has_previous": current_page.has_previous(),
                "data": dataset_data
            })
        except Exception as e:
            logger.error(f"Error listing dataset: {str(e)}")
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class WeatherView(APIView):
    permission_classes = []  # Allow unauthenticated access
    
    def get(self, request):
        try:
            # Get location parameters
            lat = request.GET.get('lat')
            lon = request.GET.get('lon')
            
            if not lat or not lon:
                return Response(
                    {"error": "Latitude and longitude parameters are required"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Use Open-Meteo API (free, no API key required)
            url = f"https://api.open-meteo.com/v1/forecast"
            params = {
                'latitude': float(lat),
                'longitude': float(lon),
                'current': 'precipitation,rain,weather_code',
                'timezone': 'auto'
            }
            
            response = requests.get(url, params=params, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                
                # Parse the weather data
                current = data.get('current', {})
                
                # Extract current rainfall data
                current_weather = {
                    'rainfall': current.get('rain', current.get('precipitation', 0.0)),
                    'weather_code': current.get('weather_code', 0),
                    'latitude': float(lat),
                    'longitude': float(lon),
                    'timestamp': data.get('current_units', {}).get('time', ''),
                }
                
                return Response({
                    'current_weather': current_weather,
                })
            else:
                return Response(
                    {"error": f"Weather API returned status {response.status_code}"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
                
        except Exception as e:
            logger.error(f"Error in weather API: {str(e)}")
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class RootView(APIView):
    permission_classes = []  # Allow unauthenticated access
    renderer_classes = [JSONRenderer]
    
    def get(self, request, format=None):
        return Response({
            "message": "SoilSync API is running",
            "status": "ok",
            "version": "1.0"
        })


