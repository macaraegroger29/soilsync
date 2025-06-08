from django.contrib import admin
from django.contrib.auth import get_user_model
from .models import SoilData, Dataset
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

User = get_user_model()

@admin.register(User)
class CustomUserAdmin(BaseUserAdmin):
    list_display = ('username', 'email', 'role', 'is_active', 'date_joined')
    list_filter = ('role', 'is_active', 'is_staff', 'is_superuser')
    search_fields = ('username', 'email')
    ordering = ('-date_joined',)
    
    # Add role field to the user form
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Custom Fields', {'fields': ('role',)}),
    )
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ('Custom Fields', {'fields': ('role',)}),
    )

    def delete_queryset(self, request, queryset):
        # This will properly handle related records deletion
        for obj in queryset:
            obj.delete()

@admin.register(SoilData)
class SoilDataAdmin(admin.ModelAdmin):
    list_display = ('user', 'prediction', 'created_at', 'nitrogen', 'phosphorus', 'potassium', 'ph')
    list_filter = ('prediction', 'created_at')
    search_fields = ('user__username', 'prediction')
    ordering = ('-created_at',)
    raw_id_fields = ('user',)

@admin.register(Dataset)
class DatasetAdmin(admin.ModelAdmin):
    list_display = ('label', 'nitrogen', 'phosphorus', 'potassium', 'ph', 'created_at')
    list_filter = ('label', 'created_at')
    search_fields = ('label',)
    ordering = ('-created_at',)
