from django.urls import path
from .views import (
    CustomTokenObtainPairView,
    RegisterView,
    PredictSoilView,
    ListUsersView,
    ListDatasetView,
    WeatherView,
    root_view,
    retrain_model,
    get_model_versions,
    get_model_details,
    deploy_model,
    upload_csv_data,
    get_training_logs,
)
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('', root_view),
    path('token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('register/', RegisterView.as_view(), name='register'),
    path('predict/', PredictSoilView.as_view(), name='predict'),
    path('retrain/', retrain_model, name='retrain_model'),
    path('users/', ListUsersView.as_view(), name='list_users'),
    path('dataset/', ListDatasetView.as_view(), name='list_dataset'),
    path('weather/', WeatherView.as_view(), name='weather'),
    path('models/', get_model_versions, name='get_model_versions'),
    path('models/<int:version_id>/', get_model_details, name='get_model_details'),
    path('models/<int:version_id>/deploy/', deploy_model, name='deploy_model'),
    path('upload-csv/', upload_csv_data, name='upload_csv_data'),
    path('models/<int:version_id>/logs/', get_training_logs, name='get_training_logs'),
]
