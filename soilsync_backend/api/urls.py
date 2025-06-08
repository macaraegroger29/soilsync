from django.urls import path
from .views import (
    CustomTokenObtainPairView,
    RegisterView,
    PredictSoilView,
    ListUsersView,
    ListDatasetView
)
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('register/', RegisterView.as_view(), name='register'),
    path('predict/', PredictSoilView.as_view(), name='predict'),
    path('users/', ListUsersView.as_view(), name='list_users'),
    path('dataset/', ListDatasetView.as_view(), name='list_dataset'),
]
