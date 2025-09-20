from django.contrib import admin
from .models import SensorDevice, SoilData, CropRecommendation, SystemFeedback, ActivityLog, PredictionResult

@admin.register(SensorDevice)
class SensorDeviceAdmin(admin.ModelAdmin):
    list_display = ('name', 'device_id', 'location', 'status', 'date_installed', 'last_updated')
    list_filter = ('status', 'date_installed')
    search_fields = ('name', 'device_id', 'location')

@admin.register(SoilData)
class SoilDataAdmin(admin.ModelAdmin):
    list_display = ('user', 'sensor', 'location', 'nitrogen', 'phosphorus', 'potassium', 'ph_level', 'moisture', 'temperature', 'rainfall', 'timestamp')
    list_filter = ('timestamp', 'location')
    search_fields = ('user__username', 'sensor__name', 'location')
    raw_id_fields = ('user', 'sensor')

@admin.register(CropRecommendation)
class CropRecommendationAdmin(admin.ModelAdmin):
    list_display = ('soil_data', 'recommended_crop', 'confidence_score', 'recommendation_date')
    list_filter = ('recommendation_date', 'recommended_crop')
    search_fields = ('recommended_crop', 'soil_data__location')
    raw_id_fields = ('soil_data',)

@admin.register(SystemFeedback)
class SystemFeedbackAdmin(admin.ModelAdmin):
    list_display = ('user', 'feedback_type', 'title', 'status', 'date_submitted')
    list_filter = ('feedback_type', 'status', 'date_submitted')
    search_fields = ('user__username', 'title', 'description')
    raw_id_fields = ('user',)

@admin.register(ActivityLog)
class ActivityLogAdmin(admin.ModelAdmin):
    list_display = ('user', 'action', 'timestamp', 'ip_address')
    list_filter = ('timestamp', 'action')
    search_fields = ('user__username', 'action', 'description')
    raw_id_fields = ('user',)

@admin.register(PredictionResult)
class PredictionResultAdmin(admin.ModelAdmin):
    list_display = ('crop_name', 'nitrogen', 'phosphorus', 'potassium', 'temperature', 'humidity', 'ph', 'rainfall', 'predicted_yield', 'confidence_score', 'created_at')
    list_filter = ('created_at', 'crop_name')
    search_fields = ('crop_name', 'location', 'device_id', 'user_id')
