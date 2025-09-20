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
