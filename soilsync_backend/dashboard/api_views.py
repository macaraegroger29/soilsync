from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from .models import PredictionResult, SoilData, SensorDevice, CropRecommendation, SystemFeedback, ActivityLog
from .serializers import (
    PredictionResultSerializer, 
    SoilDataSerializer, 
    SensorDeviceSerializer, 
    CropRecommendationSerializer,
    SystemFeedbackSerializer,
    ActivityLogSerializer
)
import logging

logger = logging.getLogger(__name__)

# Prediction API endpoints
@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def receive_prediction(request):
    """Receive prediction data from the Flutter app"""
    try:
        serializer = PredictionResultSerializer(data=request.data)
        if serializer.is_valid():
            prediction = serializer.save()
            logger.info(f"Received prediction: {prediction.crop_name}")
            return Response({
                'status': 'success',
                'message': 'Prediction saved successfully',
                'id': prediction.id
            }, status=status.HTTP_201_CREATED)
        else:
            logger.error(f"Invalid prediction data: {serializer.errors}")
            return Response({
                'status': 'error',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        logger.error(f"Error receiving prediction: {str(e)}")
        return Response({
            'status': 'error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_predictions(request):
    """Get all predictions for dashboard display"""
    try:
        predictions = PredictionResult.objects.all()[:100]
        serializer = PredictionResultSerializer(predictions, many=True)
        return Response({
            'status': 'success',
            'data': serializer.data
        })
    except Exception as e:
        logger.error(f"Error fetching predictions: {str(e)}")
        return Response({
            'status': 'error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_predictions_realtime(request):
    """Get latest predictions for real-time dashboard updates"""
    try:
        predictions = PredictionResult.objects.order_by('-created_at')[:50]
        serializer = PredictionResultSerializer(predictions, many=True)
        return Response({
            'status': 'success',
            'data': serializer.data,
            'timestamp': timezone.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Error fetching real-time predictions: {str(e)}")
        return Response({
            'status': 'error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# Soil Data API endpoints
@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def soil_data_list_create(request):
    """List or create soil data entries"""
    if request.method == 'GET':
        soil_data = SoilData.objects.all()
        serializer = SoilDataSerializer(soil_data, many=True)
        return Response(serializer.data)
    
    elif request.method == 'POST':
        serializer = SoilDataSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([AllowAny])
def soil_data_detail(request, pk):
    """Retrieve, update or delete a soil data entry"""
    try:
        soil_data = SoilData.objects.get(pk=pk)
    except SoilData.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
    
    if request.method == 'GET':
        serializer = SoilDataSerializer(soil_data)
        return Response(serializer.data)
    
    elif request.method == 'PUT':
        serializer = SoilDataSerializer(soil_data, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    elif request.method == 'DELETE':
        soil_data.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

# Sensor Device API endpoints
@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def sensor_device_list_create(request):
    """List or create sensor devices"""
    if request.method == 'GET':
        sensors = SensorDevice.objects.all()
        serializer = SensorDeviceSerializer(sensors, many=True)
        return Response(serializer.data)
    
    elif request.method == 'POST':
        serializer = SensorDeviceSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# Crop Recommendation API endpoints
@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def crop_recommendation_list_create(request):
    """List or create crop recommendations"""
    if request.method == 'GET':
        recommendations = CropRecommendation.objects.all()
        serializer = CropRecommendationSerializer(recommendations, many=True)
        return Response(serializer.data)
    
    elif request.method == 'POST':
        serializer = CropRecommendationSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# Dashboard Stats API
@api_view(['GET'])
@permission_classes([AllowAny])
def dashboard_stats(request):
    """Get dashboard statistics"""
    try:
        total_predictions = PredictionResult.objects.count()
        total_soil_data = SoilData.objects.count()
        total_sensors = SensorDevice.objects.count()
        total_recommendations = CropRecommendation.objects.count()
        
        return Response({
            'status': 'success',
            'data': {
                'total_predictions': total_predictions,
                'total_soil_data': total_soil_data,
                'total_sensors': total_sensors,
                'total_recommendations': total_recommendations
            }
        })
    except Exception as e:
        logger.error(f"Error fetching dashboard stats: {str(e)}")
        return Response({
            'status': 'error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
