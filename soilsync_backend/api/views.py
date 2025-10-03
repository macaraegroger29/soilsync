from django.contrib.auth import get_user_model
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework.views import APIView
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth import authenticate
import logging
import requests
import json
from .serializers import CustomUserSerializer, SoilDataSerializer
from .models import SoilData, Dataset, ModelVersion, TrainingLog
import joblib
import pandas as pd
import numpy as np
import os
from django.conf import settings
from django.core.paginator import Paginator
from rest_framework.renderers import JSONRenderer
from django.http import JsonResponse
from rest_framework import serializers
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated

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
    username_field = 'username_or_email'


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def retrain_model(request):
    """Enhanced retraining with detailed metrics and model versioning."""
    try:
        from sklearn.ensemble import RandomForestClassifier
        from sklearn.model_selection import train_test_split
        from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix, classification_report
        from sklearn.preprocessing import LabelEncoder
        import uuid
        from datetime import datetime
        
        # Load dataset from DB
        qs = Dataset.objects.all().values(
            'nitrogen', 'phosphorus', 'potassium', 'temperature', 'humidity', 'ph', 'rainfall', 'label'
        )
        data = list(qs)
        if not data:
            return Response({'success': False, 'error': 'No dataset records found.'}, status=status.HTTP_400_BAD_REQUEST)

        df = pd.DataFrame(data)
        X = df[['nitrogen', 'phosphorus', 'potassium', 'temperature', 'humidity', 'ph', 'rainfall']]
        y = df['label']

        # Encode labels for consistent handling
        le = LabelEncoder()
        y_encoded = le.fit_transform(y)
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(X, y_encoded, test_size=0.2, random_state=42, stratify=y_encoded)
        
        # Train model
        model_new = RandomForestClassifier(n_estimators=200, random_state=42)
        model_new.fit(X_train, y_train)
        
        # Make predictions
        y_pred = model_new.predict(X_test)
        
        # Calculate metrics
        accuracy = accuracy_score(y_test, y_pred)
        precision = precision_score(y_test, y_pred, average='weighted')
        recall = recall_score(y_test, y_pred, average='weighted')
        f1 = f1_score(y_test, y_pred, average='weighted')
        
        # Confusion matrix
        cm = confusion_matrix(y_test, y_pred)
        cm_labels = le.classes_
        confusion_matrix_data = {
            'matrix': cm.tolist(),
            'labels': cm_labels.tolist()
        }
        
        # Feature importance
        feature_names = ['nitrogen', 'phosphorus', 'potassium', 'temperature', 'humidity', 'ph', 'rainfall']
        feature_importance = dict(zip(feature_names, model_new.feature_importances_.tolist()))
        
        # Training metrics (simplified for now)
        training_metrics = {
            'train_accuracy': accuracy,  # In real scenario, calculate on training set
            'val_accuracy': accuracy,
            'epochs': [1, 2, 3, 4, 5],  # Placeholder
            'train_loss': [0.8, 0.6, 0.4, 0.3, 0.2],  # Placeholder
            'val_loss': [0.9, 0.7, 0.5, 0.4, 0.3]  # Placeholder
        }
        
        # Generate version
        version = f"v{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        # Save model with version
        model_path = os.path.join(settings.BASE_DIR, 'lib', 'models', f'RandomForest_{version}.pkl')
        os.makedirs(os.path.dirname(model_path), exist_ok=True)
        joblib.dump(model_new, model_path)
        
        # Also save as active model
        active_model_path = os.path.join(settings.BASE_DIR, 'lib', 'models', 'RandomForest.pkl')
        joblib.dump(model_new, active_model_path)
        
        # Create model version record
        model_version = ModelVersion.objects.create(
            version=version,
            model_path=model_path,
            dataset_size=len(df),
            accuracy=accuracy,
            precision=precision,
            recall=recall,
            f1_score=f1,
            confusion_matrix=confusion_matrix_data,
            feature_importance=feature_importance,
            training_metrics=training_metrics,
            is_active=True,
            created_by=request.user
        )
        
        # Deactivate previous versions
        ModelVersion.objects.filter(is_active=True).exclude(id=model_version.id).update(is_active=False)
        
        # Create training log
        TrainingLog.objects.create(
            model_version=model_version,
            log_data={
                'training_data_size': len(X_train),
                'test_data_size': len(X_test),
                'unique_labels': len(le.classes_),
                'model_params': {
                    'n_estimators': 200,
                    'random_state': 42
                },
                'classification_report': classification_report(y_test, y_pred, output_dict=True)
            }
        )
        
        return Response({
            'success': True,
            'version': version,
            'dataset_size': len(df),
            'metrics': {
                'accuracy': accuracy,
                'precision': precision,
                'recall': recall,
                'f1_score': f1
            },
            'confusion_matrix': confusion_matrix_data,
            'feature_importance': feature_importance,
            'training_metrics': training_metrics,
            'model_path': model_path
        })
        
    except Exception as e:
        logger.exception('Model retraining failed')
        return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Replace the username field with username_or_email
        if 'username' in self.fields:
            self.fields['username_or_email'] = self.fields.pop('username')
            self.fields['username_or_email'].label = 'Username or Email'
    
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role
        return token

class CustomTokenObtainPairView(APIView):
    permission_classes = []

    def post(self, request, *args, **kwargs):
        logger.info("=== Login Attempt ===")
        logger.info(f"Username or Email: {request.data.get('username_or_email')}")
        logger.info(f"Request data: {request.data}")
        logger.info(f"Request headers: {request.headers}")
        logger.info(f"Request method: {request.method}")
        logger.info(f"Request path: {request.path}")

        try:
            # Handle username_or_email field
            username_or_email = request.data.get('username_or_email')
            password = request.data.get('password')
            
            if not username_or_email or not password:
                return Response(
                    {"error": "Must include 'username_or_email' and 'password'"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Try to find user by username first
            user = User.objects.filter(username=username_or_email).first()
            if not user:
                # If not found by username, try email
                user = User.objects.filter(email=username_or_email).first()
                if not user:
                    return Response(
                        {"error": "No user found with this username or email"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            # Authenticate the user
            authenticated_user = authenticate(username=user.username, password=password)
            if not authenticated_user:
                return Response(
                    {"error": "Invalid password"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            if not authenticated_user.is_active:
                return Response(
                    {"error": "User account is disabled"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Generate tokens
            from rest_framework_simplejwt.tokens import RefreshToken
            refresh = RefreshToken.for_user(authenticated_user)
            
            # Add role to token
            refresh['role'] = authenticated_user.role
            
            logger.info(f"User found: {authenticated_user.username}")
            logger.info(f"User is superuser: {authenticated_user.is_superuser}")
            logger.info(f"User role: {authenticated_user.role}")

            # Always set role to admin for superusers
            if authenticated_user.is_superuser:
                role = "admin"
            else:
                role = getattr(authenticated_user, 'role', 'user')
            
            response_data = {
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'role': role
            }
            
            logger.info(f"Login successful for user: {authenticated_user.username}")
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Unexpected error during login: {str(e)}")
            # Provide more specific error messages
            if "more than one" in str(e):
                return Response(
                    {"error": "Multiple accounts found with this email. Please contact support."},
                    status=status.HTTP_400_BAD_REQUEST
                )
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

                # Get confidence level for the top prediction
                confidence = top_crops[0]['confidence'] if top_crops else 1.0

                # Save the data with prediction and confidence
                soil_data = serializer.save(
                    user=request.user,
                    prediction=prediction,
                    confidence=confidence
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
            print(f'[DEBUG] Open-Meteo API URL: {response.url}')
            print(f'[DEBUG] Open-Meteo API Response: {response.text}')
            
            if response.status_code == 200:
                data = response.json()
                
                # Parse the weather data
                current = data.get('current', {})
                print(f'[DEBUG] Parsed current: {current}')
                # Extract current rainfall data
                current_weather = {
                    'precipitation': current.get('rain', current.get('precipitation', 0.0)),
                    'weather_code': current.get('weather_code', 0),
                    'latitude': float(lat),
                    'longitude': float(lon),
                    'timestamp': data.get('current_units', {}).get('time', ''),
                }
                print(f'[DEBUG] Returning current_weather: {current_weather}')
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

def root_view(request):
    return JsonResponse({"status": "ok"})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_model_versions(request):
    """Get all model versions with their metrics."""
    try:
        versions = ModelVersion.objects.all().order_by('-created_at')
        version_data = []
        for version in versions:
            version_data.append({
                'id': version.id,
                'version': version.version,
                'dataset_size': version.dataset_size,
                'accuracy': version.accuracy,
                'precision': version.precision,
                'recall': version.recall,
                'f1_score': version.f1_score,
                'is_active': version.is_active,
                'created_at': version.created_at,
                'created_by': version.created_by.username
            })
        
        return Response({
            'success': True,
            'versions': version_data
        })
    except Exception as e:
        logger.error(f"Error fetching model versions: {str(e)}")
        return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_model_details(request, version_id):
    """Get detailed metrics for a specific model version."""
    try:
        version = ModelVersion.objects.get(id=version_id)
        
        return Response({
            'success': True,
            'version': {
                'id': version.id,
                'version': version.version,
                'dataset_size': version.dataset_size,
                'accuracy': version.accuracy,
                'precision': version.precision,
                'recall': version.recall,
                'f1_score': version.f1_score,
                'confusion_matrix': version.confusion_matrix,
                'feature_importance': version.feature_importance,
                'training_metrics': version.training_metrics,
                'is_active': version.is_active,
                'created_at': version.created_at,
                'created_by': version.created_by.username
            }
        })
    except ModelVersion.DoesNotExist:
        return Response({'success': False, 'error': 'Model version not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Error fetching model details: {str(e)}")
        return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def deploy_model(request, version_id):
    """Deploy a specific model version as the active model."""
    try:
        version = ModelVersion.objects.get(id=version_id)
        
        # Deactivate all other versions
        ModelVersion.objects.filter(is_active=True).update(is_active=False)
        
        # Activate the selected version
        version.is_active = True
        version.save()
        
        # Copy the model file to the active location
        import shutil
        active_model_path = os.path.join(settings.BASE_DIR, 'lib', 'models', 'RandomForest.pkl')
        shutil.copy2(version.model_path, active_model_path)
        
        # Reload the global model
        global model
        model = joblib.load(active_model_path)
        
        return Response({
            'success': True,
            'message': f'Model version {version.version} deployed successfully',
            'active_version': version.version
        })
    except ModelVersion.DoesNotExist:
        return Response({'success': False, 'error': 'Model version not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Error deploying model: {str(e)}")
        return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_csv_data(request):
    """Upload CSV data to merge with existing dataset."""
    try:
        if 'file' not in request.FILES:
            return Response({'success': False, 'error': 'No file provided'}, status=status.HTTP_400_BAD_REQUEST)
        
        file = request.FILES['file']
        merge_mode = request.data.get('merge_mode', 'merge')  # 'merge' or 'replace'
        
        # Read CSV
        df = pd.read_csv(file)
        
        # Validate required columns
        required_columns = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall', 'label']
        if not all(col in df.columns for col in required_columns):
            return Response({
                'success': False, 
                'error': f'CSV must contain columns: {required_columns}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # If replace mode, clear existing data
        if merge_mode == 'replace':
            Dataset.objects.all().delete()
        
        # Add new data
        records_added = 0
        for _, row in df.iterrows():
            Dataset.objects.create(
                nitrogen=row['N'],
                phosphorus=row['P'],
                potassium=row['K'],
                temperature=row['temperature'],
                humidity=row['humidity'],
                ph=row['ph'],
                rainfall=row['rainfall'],
                label=row['label']
            )
            records_added += 1
        
        return Response({
            'success': True,
            'records_added': records_added,
            'total_records': Dataset.objects.count(),
            'merge_mode': merge_mode
        })
        
    except Exception as e:
        logger.error(f"Error uploading CSV: {str(e)}")
        return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_training_logs(request, version_id):
    """Get training logs for a specific model version."""
    try:
        version = ModelVersion.objects.get(id=version_id)
        logs = TrainingLog.objects.filter(model_version=version).order_by('-created_at')
        
        log_data = []
        for log in logs:
            log_data.append({
                'id': log.id,
                'log_data': log.log_data,
                'created_at': log.created_at
            })
        
        return Response({
            'success': True,
            'logs': log_data
        })
    except ModelVersion.DoesNotExist:
        return Response({'success': False, 'error': 'Model version not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Error fetching training logs: {str(e)}")
        return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


