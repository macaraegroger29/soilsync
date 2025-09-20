from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from .models import SoilData, CropRecommendation
from .serializers import CropRecommendationSerializer
from .services.crop_recommendation_service import CropRecommendationService

User = get_user_model()


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_recommendation(request):
    """
    Generate crop recommendation for specific soil data
    """
    try:
        soil_data_id = request.data.get('soil_data_id')
        
        if not soil_data_id:
            return Response(
                {'error': 'soil_data_id is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        service = CropRecommendationService()
        recommendation = service.generate_recommendations(soil_data_id)
        
        if recommendation:
            serializer = CropRecommendationSerializer(recommendation)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        else:
            return Response(
                {'error': 'Failed to generate recommendation or soil data not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
            
    except Exception as e:
        return Response(
            {'error': f'Failed to generate recommendation: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_top_recommendations(request, soil_data_id):
    """
    Get top 3 crop recommendations for specific soil data
    """
    try:
        soil_data = SoilData.objects.get(id=soil_data_id)
        service = CropRecommendationService()
        
        recommendations = service.get_top_recommendations(soil_data, top_n=3)
        
        return Response({
            'soil_data_id': soil_data_id,
            'location': soil_data.location,
            'recommendations': recommendations
        }, status=status.HTTP_200_OK)
        
    except SoilData.DoesNotExist:
        return Response(
            {'error': 'Soil data not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': f'Failed to get recommendations: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_recommendation_stats(request):
    """
    Get recommendation statistics for dashboard
    """
    try:
        stats = {
            'total_recommendations': CropRecommendation.objects.count(),
            'high_suitability': CropRecommendation.objects.filter(suitability_score__gte=80).count(),
            'medium_suitability': CropRecommendation.objects.filter(suitability_score__gte=60, suitability_score__lt=80).count(),
            'low_suitability': CropRecommendation.objects.filter(suitability_score__lt=60).count(),
            'recent_recommendations': CropRecommendation.objects.filter(
                recommendation_date__gte='2024-01-01'
            ).count()
        }
        
        return Response(stats, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': f'Failed to fetch stats: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
