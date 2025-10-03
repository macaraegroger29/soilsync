from django.contrib.auth.models import AbstractUser, Group, Permission
from django.db import models
from django.db.models import CASCADE

class CustomUser(AbstractUser):
    ROLE_CHOICES = (
        ('admin', 'Admin'),
        ('user', 'User'),
    )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='user')

    groups = models.ManyToManyField(
        Group, 
        related_name="customuser_set",
        blank=True,
        help_text="The groups this user belongs to."
    )
    user_permissions = models.ManyToManyField(
        Permission,
        related_name="customuser_set",
        blank=True,
        help_text="Specific permissions for this user."
    )

    def save(self, *args, **kwargs):
        if self.is_superuser:
            self.role = 'admin'
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        self.soil_data.all().delete()
        super().delete(*args, **kwargs)

    class Meta:
        db_table = 'custom_user'
        verbose_name = 'user'
        verbose_name_plural = 'users'

class Dataset(models.Model):
    nitrogen = models.FloatField()
    phosphorus = models.FloatField()
    potassium = models.FloatField()
    temperature = models.FloatField()
    humidity = models.FloatField()
    ph = models.FloatField()
    rainfall = models.FloatField()
    label = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Dataset entry - {self.label} ({self.created_at})"

    class Meta:
        db_table = 'training_dataset'

class SoilData(models.Model):
    user = models.ForeignKey(
        CustomUser,
        on_delete=CASCADE,
        related_name='soil_data',
        db_index=True
    )
    nitrogen = models.FloatField()
    phosphorus = models.FloatField()
    potassium = models.FloatField()
    temperature = models.FloatField()
    humidity = models.FloatField()
    ph = models.FloatField()
    rainfall = models.FloatField()
    prediction = models.CharField(max_length=100)
    confidence = models.FloatField(null=True, blank=True)  # Store confidence level for predictions
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username}'s soil data - {self.created_at}"

    class Meta:
        db_table = 'soil_data'
        ordering = ['-created_at']

class ModelVersion(models.Model):
    version = models.CharField(max_length=50, unique=True)
    model_path = models.CharField(max_length=500)
    dataset_size = models.IntegerField()
    accuracy = models.FloatField()
    precision = models.FloatField()
    recall = models.FloatField()
    f1_score = models.FloatField()
    confusion_matrix = models.JSONField()
    feature_importance = models.JSONField()
    training_metrics = models.JSONField()  # Training vs validation accuracy
    is_active = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(
        CustomUser,
        on_delete=CASCADE,
        related_name='model_versions'
    )

    def __str__(self):
        return f"Model v{self.version} - {self.accuracy:.3f} accuracy"

    class Meta:
        db_table = 'model_versions'
        ordering = ['-created_at']

class TrainingLog(models.Model):
    model_version = models.ForeignKey(
        ModelVersion,
        on_delete=CASCADE,
        related_name='training_logs'
    )
    log_data = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Training log for v{self.model_version.version}"

    class Meta:
        db_table = 'training_logs'
        ordering = ['-created_at']