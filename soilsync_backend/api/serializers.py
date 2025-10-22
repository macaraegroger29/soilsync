from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import SoilData

User = get_user_model()

class CustomUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('username', 'password', 'email', 'role', 'phone', 'location')
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            password=validated_data['password'],
            email=validated_data.get('email', ''),
            role=validated_data.get('role', 'user'),
            phone=validated_data.get('phone', ''),
            location=validated_data.get('location', '')
        )
        return user

class SoilDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = SoilData
        fields = ('id', 'nitrogen', 'phosphorus', 'potassium', 'temperature', 
                 'humidity', 'ph', 'rainfall', 'prediction', 'created_at')
        read_only_fields = ('prediction', 'created_at') 