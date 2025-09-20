from rest_framework import serializers
from .models import PredictionResult, SoilData, SensorDevice, CropRecommendation, SystemFeedback, ActivityLog

class PredictionResultSerializer(serializers.ModelSerializer):
    class Meta:
        model = PredictionResult
        fields = '__all__'

class SoilDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = SoilData
        fields = '__all__'

class SensorDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = SensorDevice
        fields = '__all__'

class CropRecommendationSerializer(serializers.ModelSerializer):
    class Meta:
        model = CropRecommendation
        fields = '__all__'

class SystemFeedbackSerializer(serializers.ModelSerializer):
    class Meta:
        model = SystemFeedback
        fields = '__all__'

class ActivityLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = ActivityLog
        fields = '__all__'
