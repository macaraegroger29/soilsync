from django.contrib import admin
from django.urls import path, include
from api.views import RootView

urlpatterns = [
    path('', RootView.as_view(), name='api-root'),
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
]
