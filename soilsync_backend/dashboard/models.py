from django.db import models
from django.utils import timezone
from django.contrib.auth import get_user_model

User = get_user_model()

class SensorDevice(models.Model):
    """Model for IoT sensor devices"""
    name = models.CharField(max_length=100, default='')
    device_id = models.CharField(max_length=100, unique=True, default='')
    location = models.CharField(max_length=255, default='')
    status = models.CharField(max_length=20, choices=[
        ('active', 'Active'),
        ('inactive', 'Inactive'),
        ('maintenance', 'Maintenance'),
    ], default='active')
    date_installed = models.DateTimeField(default=timezone.now)
    last_updated = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.name} ({self.device_id})"

class SoilData(models.Model):
    """Model for soil sensor readings"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='dashboard_soil_data')
    sensor = models.ForeignKey(SensorDevice, on_delete=models.CASCADE, related_name='dashboard_readings')
    location = models.CharField(max_length=255, default='')
    nitrogen = models.FloatField(default=0.0)
    phosphorus = models.FloatField(default=0.0)
    potassium = models.FloatField(default=0.0)
    ph_level = models.FloatField(default=7.0)
    moisture = models.FloatField(default=0.0)
    temperature = models.FloatField(default=0.0)
    rainfall = models.FloatField(default=0.0)
    timestamp = models.DateTimeField(default=timezone.now)
    
    class Meta:
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"Soil data from {self.location} at {self.timestamp.strftime('%Y-%m-%d %H:%M')}"

class CropRecommendation(models.Model):
    """Model for crop recommendations based on soil data"""
    soil_data = models.ForeignKey(SoilData, on_delete=models.CASCADE, related_name='dashboard_recommendations')
    recommended_crop = models.CharField(max_length=100, default='')
    confidence_score = models.FloatField(default=0.0)
    recommendation_date = models.DateTimeField(default=timezone.now)
    additional_info = models.TextField(blank=True, null=True)
    
    class Meta:
        ordering = ['-recommendation_date']
    
    def __str__(self):
        return f"{self.recommended_crop} for {self.soil_data.location}"

class SystemFeedback(models.Model):
    """Model for user feedback about the system"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='dashboard_feedback')
    feedback_type = models.CharField(max_length=50, choices=[
        ('bug', 'Bug Report'),
        ('feature', 'Feature Request'),
        ('improvement', 'Improvement'),
        ('general', 'General Feedback'),
    ], default='general')
    title = models.CharField(max_length=200, default='')
    description = models.TextField(default='')
    date_submitted = models.DateTimeField(default=timezone.now)
    status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ], default='pending')
    
    class Meta:
        ordering = ['-date_submitted']
    
    def __str__(self):
        return f"{self.title} by {self.user.username}"

class ActivityLog(models.Model):
    """Model for tracking user activities"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='dashboard_activity_logs')
    action = models.CharField(max_length=100, default='')
    description = models.TextField(default='')
    timestamp = models.DateTimeField(default=timezone.now)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    
    class Meta:
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"{self.user.username} - {self.action} at {self.timestamp}"

class PredictionResult(models.Model):
    """Model to store crop prediction results from the Flutter app"""
    crop_name = models.CharField(max_length=100, default='')
    nitrogen = models.FloatField(default=0.0)
    phosphorus = models.FloatField(default=0.0)
    potassium = models.FloatField(default=0.0)
    temperature = models.FloatField(default=0.0)
    humidity = models.FloatField(default=0.0)
    ph = models.FloatField(default=7.0)
    rainfall = models.FloatField(default=0.0)
    predicted_yield = models.FloatField(default=0.0)
    confidence_score = models.FloatField(default=0.0)
    location = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(default=timezone.now)
    device_id = models.CharField(max_length=255, blank=True, null=True)
    user_id = models.CharField(max_length=255, blank=True, null=True)
    
    class Meta:
        ordering = ['-created_at']
        
    def __str__(self):
        return f"{self.crop_name} - {self.predicted_yield} ({self.created_at.strftime('%Y-%m-%d %H:%M')})"
