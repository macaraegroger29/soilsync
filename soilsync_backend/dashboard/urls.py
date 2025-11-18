from django.urls import path
from .views import (
    dashboard_login, dashboard_logout, dashboard_register, database_dashboard,
    crop_recommendations_table, system_feedback_table,
    activity_logs_table, users_table, user_settings, user_profile,
    edit_user, delete_user, toggle_user_status, api_soil_data_table,
    export_api_soil_data_csv, export_api_soil_data_pdf, soil_parameter_trends
)
from .api_views import (
    receive_prediction, get_predictions, get_predictions_realtime,
    soil_data_list_create, soil_data_detail, sensor_device_list_create,
    crop_recommendation_list_create, dashboard_stats
)

# Web dashboard URLs
urlpatterns = [
    # Authentication
    path('login/', dashboard_login, name='dashboard_login'),
    path('logout/', dashboard_logout, name='dashboard_logout'),
    path('register/', dashboard_register, name='dashboard_register'),
    
    # Dashboard pages
    path('', database_dashboard, name='database_dashboard'),
    path('api-soil-data/', api_soil_data_table, name='api_soil_data_table'),
    path('api-soil-data/export/csv/', export_api_soil_data_csv, name='export_api_soil_data_csv'),
    path('api-soil-data/export/pdf/', export_api_soil_data_pdf, name='export_api_soil_data_pdf'),
    path('crop-recommendations/', crop_recommendations_table, name='crop_recommendations_table'),
    path('system-feedback/', system_feedback_table, name='system_feedback_table'),
    path('activity-logs/', activity_logs_table, name='activity_logs_table'),
    path('users/', users_table, name='users_table'),
    path('edit-user/<int:pk>/', edit_user, name='edit_user'),
    path('toggle-user-status/<int:pk>/', toggle_user_status, name='toggle_user_status'),
    path('delete-user/<int:pk>/', delete_user, name='delete_user'),
    path('settings/', user_settings, name='user_settings'),
    path('profile/', user_profile, name='user_profile'),
    
    # API endpoints for Flutter app
    path('api/stats/', dashboard_stats, name='dashboard_stats_api'),
    path('api/predictions/', receive_prediction, name='receive_prediction'),
    path('api/predictions/all/', get_predictions, name='get_predictions'),
    path('api/predictions/realtime/', get_predictions_realtime, name='get_predictions_realtime'),
    path('api/soil-data/', soil_data_list_create, name='soil_data_list_create'),
    path('api/soil-data/<int:pk>/', soil_data_detail, name='soil_data_detail'),
    path('api/sensors/', sensor_device_list_create, name='sensor_device_list_create'),
    path('api/crop-recommendations/', crop_recommendation_list_create, name='crop_recommendation_list_create'),

    # Trends API endpoint
    path('api/soil-parameter-trends/', soil_parameter_trends, name='soil_parameter_trends'),
]
