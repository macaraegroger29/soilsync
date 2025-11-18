from django.shortcuts import render, redirect, get_object_or_404
from .models import SoilData, SensorDevice, CropRecommendation, ActivityLog, SystemFeedback
from api.models import SoilData as APISoilData
from django.contrib.auth import get_user_model, authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.utils import timezone
from django.contrib import messages
from django.db import IntegrityError
from django.http import HttpResponse
import csv
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph
from reportlab.lib import colors
import logging

logger = logging.getLogger(__name__)

User = get_user_model()

# Create your views here.

def dashboard_login(request):
    if request.user.is_authenticated:
        return redirect('database_dashboard')
    
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        raw_username = username
        username = (username or '').strip()
        password = password or ''
        password_stripped = password.strip()
        try:
            user_ci = User.objects.filter(username__iexact=username).first()
            user_exists = user_ci is not None
            logger.info(
                f"[dashboard_login] POST raw_username={raw_username!r}, normalized_username={username!r}, user_exists={user_exists}, pwd_len={len(password)}, pwd_trimmed={'yes' if password != password_stripped else 'no'}"
            )
        except Exception as e:
            logger.error(f"[dashboard_login] Error checking user existence: {e}")
            user_ci = None
        
        if username and password:
            auth_username = user_ci.username if user_ci else username
            user = authenticate(request, username=auth_username, password=password)
            if not user and password != password_stripped:
                user = authenticate(request, username=auth_username, password=password_stripped)
                if user:
                    logger.info("[dashboard_login] authenticated after trimming password")
            # Fallback: manual password check if backend auth failed
            if not user and user_ci and (user_ci.check_password(password) or (password != password_stripped and user_ci.check_password(password_stripped))):
                user = user_ci
                logger.info("[dashboard_login] authenticated via check_password fallback")
            logger.info(
                f"[dashboard_login] authenticate result: {bool(user)} for auth_username={auth_username!r}"
            )
            if user is not None:
                login(request, user)
                messages.success(request, f'Welcome back, {user.username}!')
                next_url = request.GET.get('next', 'database_dashboard')
                return redirect(next_url)
            else:
                messages.error(request, 'Invalid username or password!')
        else:
            messages.error(request, 'Please enter both username and password!')
    
    return render(request, 'dashboard/login.html')

def dashboard_register(request):
    if request.user.is_authenticated:
        return redirect('database_dashboard')
    
    if request.method == 'POST':
        username = request.POST.get('username')
        email = request.POST.get('email')
        password1 = request.POST.get('password1')
        password2 = request.POST.get('password2')
        role = request.POST.get('role', 'farmer')
        
        # Validation
        if not all([username, email, password1, password2, role]):
            messages.error(request, 'Please fill in all required fields!')
        elif password1 != password2:
            messages.error(request, 'Passwords do not match!')
        elif len(password1) < 8:
            messages.error(request, 'Password must be at least 8 characters long!')
        elif User.objects.filter(username=username).exists():
            messages.error(request, 'Username already exists!')
        elif User.objects.filter(email=email).exists():
            messages.error(request, 'Email already registered!')
        else:
            try:
                user = User.objects.create_user(
                    username=username,
                    email=email,
                    password=password1,
                    role=role
                )
                messages.success(request, f'Account created successfully! Please log in with your new account.')
                return redirect('dashboard_login')
            except IntegrityError:
                messages.error(request, 'An error occurred during registration. Please try again.')
    
    return render(request, 'dashboard/register.html')

def dashboard_logout(request):
    logout(request)
    messages.success(request, 'You have been logged out successfully!')
    return redirect('dashboard_login')

@login_required(login_url='dashboard_login')
def database_dashboard(request):
    # Get all data for dashboard
    users = User.objects.all()
    sensors = SensorDevice.objects.all()

    # Get traditional crop recommendations
    crop_recommendations = CropRecommendation.objects.all()

    # Get API soil data for analytics
    is_admin = request.user.role == 'admin' or request.user.is_staff
    if is_admin:
        api_soil_data = APISoilData.objects.select_related('user').all()
    else:
        api_soil_data = APISoilData.objects.select_related('user').filter(user=request.user)

    # Combined recommendations count (traditional + API)
    total_recommendations = crop_recommendations.count() + api_soil_data.count()

    # Get recent data for dashboard display (combine both types)
    recent_traditional = CropRecommendation.objects.select_related('soil_data').all().order_by('-recommendation_date')[:3]
    recent_api = api_soil_data.order_by('-created_at')[:3]

    # Combine and sort recent recommendations
    recent_recommendations = []
    for rec in recent_traditional:
        recent_recommendations.append({
            'type': 'traditional',
            'date': rec.recommendation_date,
            'crop': rec.recommended_crop,
            'location': rec.soil_data.location if rec.soil_data else 'N/A',
            'score': rec.confidence_score
        })

    for api in recent_api:
        recent_recommendations.append({
            'type': 'api',
            'date': api.created_at,
            'crop': api.prediction,
            'location': 'API Submission',
            'score': api.confidence if api.confidence else None
        })

    # Sort combined list by date
    recent_recommendations.sort(key=lambda x: x['date'], reverse=True)
    recent_recommendations = recent_recommendations[:5]

    # Analytics data from API soil data
    ph_distribution = {'acidic': 0, 'neutral': 0, 'alkaline': 0}
    crop_counts = {}

    for data in api_soil_data:
        # pH distribution
        if data.ph < 6.0:
            ph_distribution['acidic'] += 1
        elif data.ph <= 7.0:
            ph_distribution['neutral'] += 1
        else:
            ph_distribution['alkaline'] += 1

        # Crop prediction counts
        crop = data.prediction
        if crop in crop_counts:
            crop_counts[crop] += 1
        else:
            crop_counts[crop] = 1

    # Prepare chart data
    crop_labels = list(crop_counts.keys())[:4]  # Top 4 crops
    crop_data = [crop_counts.get(crop, 0) for crop in crop_labels]
    if len(crop_labels) < 4:
        crop_labels.append('Others')
        crop_data.append(sum(crop_counts.get(crop, 0) for crop in crop_counts if crop not in crop_labels[:-1]))

    # Get recent soil readings with timestamps for tracking
    recent_soil_readings = api_soil_data.order_by('-created_at')[:10]

    profile_name = request.user.get_full_name() or request.user.username if request.user.is_authenticated else 'Guest'
    profile_email = request.user.email if request.user.is_authenticated else ''

    return render(request, 'dashboard/database_dashboard.html', {
        "users": users,
        "sensors": sensors,
        "crop_recommendations": crop_recommendations,
        "api_soil_data": api_soil_data,
        "total_recommendations": total_recommendations,
        "recent_recommendations": recent_recommendations,
        "ph_distribution": ph_distribution,
        "crop_labels": crop_labels,
        "crop_data": crop_data,
        "recent_soil_readings": recent_soil_readings,
        "profile_name": profile_name,
        "profile_email": profile_email,
    })



@login_required(login_url='dashboard_login')
def sensor_devices_table(request):
    sensors = SensorDevice.objects.all().order_by('-date_installed')
    is_admin = request.user.role == 'admin' or request.user.is_staff
    return render(request, 'dashboard/sensor_devices_table.html', {
        'sensors': sensors,
        'is_admin': is_admin,
    })

@login_required(login_url='dashboard_login')
def crop_recommendations_table(request):
    from .models import CropRecommendation
    is_admin = request.user.role == 'admin' or request.user.is_staff

    # Get traditional crop recommendations
    recommendations = CropRecommendation.objects.select_related('soil_data').all().order_by('-recommendation_date')

    # Get API soil data predictions
    if is_admin:
        api_soil_data = APISoilData.objects.select_related('user').all().order_by('-created_at')
    else:
        api_soil_data = APISoilData.objects.select_related('user').filter(user=request.user).order_by('-created_at')

    profile_name = request.user.get_full_name() or request.user.username if request.user.is_authenticated else 'Guest'

    return render(request, 'dashboard/crop_recommendations_table.html', {
        'recommendations': recommendations,
        'api_soil_data': api_soil_data,
        'is_admin': is_admin,
        'profile_name': profile_name,
    })

@login_required(login_url='dashboard_login')
def combined_sensors_crop_recommendations(request):
    """Combined view for sensors and crop recommendations"""
    sensors = SensorDevice.objects.all().order_by('-date_installed')
    recommendations = CropRecommendation.objects.select_related('soil_data').all().order_by('-recommendation_date')
    is_admin = request.user.role == 'admin' or request.user.is_staff
    
    return render(request, 'dashboard/combined_sensors_crop_recommendations.html', {
        'sensors': sensors,
        'recommendations': recommendations,
        'is_admin': is_admin,
    })

@login_required(login_url='dashboard_login')
def system_feedback_table(request):
    from .models import SystemFeedback
    feedbacks = SystemFeedback.objects.select_related('user').all().order_by('-date_submitted')
    is_admin = request.user.role == 'admin' or request.user.is_staff
    return render(request, 'dashboard/system_feedback_table.html', {
        'feedbacks': feedbacks,
        'is_admin': is_admin,
    })

@login_required(login_url='dashboard_login')
def activity_logs_table(request):
    from .models import ActivityLog
    logs = ActivityLog.objects.select_related('user').all().order_by('-timestamp')
    is_admin = request.user.role == 'admin' or request.user.is_staff
    return render(request, 'dashboard/activity_logs_table.html', {
        'logs': logs,
        'is_admin': is_admin,
    })



@login_required(login_url='dashboard_login')
def user_settings(request):
    """User settings page"""
    return render(request, 'dashboard/settings.html')

@login_required(login_url='dashboard_login')
def user_profile(request):
    """User profile page"""
    is_admin = request.user.role == 'admin' or request.user.is_staff

    # Get API soil data (admins see all, users see only their own)
    if is_admin:
        api_soil_data = APISoilData.objects.select_related('user').all().order_by('-created_at')[:5]  # Recent 5 records
        api_soil_data_count = APISoilData.objects.count()
    else:
        api_soil_data = APISoilData.objects.filter(user=request.user).order_by('-created_at')[:5]  # Recent 5 records
        api_soil_data_count = APISoilData.objects.filter(user=request.user).count()

    # Get user's crop recommendations count
    recommendations_count = CropRecommendation.objects.filter(soil_data__user=request.user).count()

    # Get recent activity (API submissions)
    recent_activity = []
    for data in api_soil_data:
        if is_admin and data.user != request.user:
            action_text = f"Soil analysis by {data.user.username} - Prediction: {data.prediction or 'N/A'}"
        else:
            action_text = f"Soil analysis submitted - Prediction: {data.prediction or 'N/A'}"
        recent_activity.append({
            'action': action_text,
            'timestamp': data.created_at
        })

    return render(request, 'dashboard/profile.html', {
        'api_soil_data': api_soil_data,
        'api_soil_data_count': api_soil_data_count,
        'recommendations_count': recommendations_count,
        'recent_activity': recent_activity,
        'is_admin': is_admin,
    })

@login_required(login_url='dashboard_login')
def users_table(request):
    # Check if user is admin
    if not (request.user.role == 'admin' or request.user.is_staff):
        messages.error(request, 'Access denied. Admin privileges required.')
        return redirect('database_dashboard')
    
    # Handle user creation
    if request.method == 'POST' and 'create_user' in request.POST:
        username = request.POST.get('username')
        email = request.POST.get('email')
        password = request.POST.get('password')
        role = request.POST.get('role', 'farmer')
        
        if username and email and password:
            try:
                user = User.objects.create_user(
                    username=username,
                    email=email,
                    password=password,
                    role=role
                )
                messages.success(request, f'User "{username}" created successfully!')
                return redirect('users_table')
            except IntegrityError:
                messages.error(request, 'Username or email already exists!')
        else:
            messages.error(request, 'Please fill in all required fields!')
    
    users = User.objects.all().order_by('username')
    return render(request, 'dashboard/users_table.html', {
        'users': users,
        'is_admin': True,  # Always true since we checked above
    })

@login_required(login_url='dashboard_login')
def edit_user(request, pk):
    if not (request.user.role == 'admin' or request.user.is_staff):
        messages.error(request, 'Access denied. Admin privileges required.')
        return redirect('database_dashboard')
    
    user_to_edit = get_object_or_404(User, pk=pk)
    
    if request.method == 'POST':
        username = request.POST.get('username')
        email = request.POST.get('email')
        first_name = request.POST.get('first_name', '')
        last_name = request.POST.get('last_name', '')
        role = request.POST.get('role', 'farmer')
        is_active = request.POST.get('is_active') == 'on'
        
        if username and email:
            try:
                # Check if username or email already exists (excluding current user)
                if User.objects.exclude(pk=pk).filter(username=username).exists():
                    messages.error(request, 'Username already exists!')
                elif User.objects.exclude(pk=pk).filter(email=email).exists():
                    messages.error(request, 'Email already exists!')
                else:
                    user_to_edit.username = username
                    user_to_edit.email = email
                    user_to_edit.first_name = first_name
                    user_to_edit.last_name = last_name
                    user_to_edit.role = role
                    user_to_edit.is_active = is_active
                    user_to_edit.save()
                    
                    messages.success(request, f'User "{username}" updated successfully!')
                    return redirect('users_table')
            except IntegrityError:
                messages.error(request, 'An error occurred while updating the user.')
        else:
            messages.error(request, 'Please fill in all required fields!')
    
    return render(request, 'dashboard/edit_user.html', {
        'user_to_edit': user_to_edit,
    })

@login_required(login_url='dashboard_login')
def toggle_user_status(request, pk):
    if not (request.user.role == 'admin' or request.user.is_staff):
        messages.error(request, 'Access denied. Admin privileges required.')
        return redirect('database_dashboard')

    user_to_toggle = get_object_or_404(User, pk=pk)

    # Prevent admin from deactivating themselves
    if user_to_toggle == request.user:
        messages.error(request, 'You cannot deactivate your own account!')
        return redirect('users_table')

    # Toggle the active status
    user_to_toggle.is_active = not user_to_toggle.is_active
    user_to_toggle.save()

    status_text = 'activated' if user_to_toggle.is_active else 'deactivated'
    messages.success(request, f'User "{user_to_toggle.username}" has been {status_text} successfully!')
    return redirect('users_table')

@login_required(login_url='dashboard_login')
def delete_user(request, pk):
    if not (request.user.role == 'admin' or request.user.is_staff):
        messages.error(request, 'Access denied. Admin privileges required.')
        return redirect('database_dashboard')

    user_to_delete = get_object_or_404(User, pk=pk)

    # Prevent admin from deleting themselves
    if user_to_delete == request.user:
        messages.error(request, 'You cannot delete your own account!')
        return redirect('users_table')

    if request.method == 'POST':
        username = user_to_delete.username
        user_to_delete.delete()
        messages.success(request, f'User "{username}" deleted successfully!')
        return redirect('users_table')

    return render(request, 'dashboard/delete_user.html', {
        'user_to_delete': user_to_delete,
    })

@login_required(login_url='dashboard_login')
def api_soil_data_table(request):
    """Dedicated view for API soil data table"""
    is_admin = request.user.role == 'admin' or request.user.is_staff

    if is_admin:
        # Admins see all data
        api_soil_data = APISoilData.objects.select_related('user').all().order_by('-created_at')
    else:
        # Normal users see only their own data
        api_soil_data = APISoilData.objects.select_related('user').filter(user=request.user).order_by('-created_at')

    # Calculate averages from the actual data
    if api_soil_data.exists():
        avg_ph = round(sum(data.ph for data in api_soil_data) / api_soil_data.count(), 1)
        avg_humidity = round(sum(data.humidity for data in api_soil_data) / api_soil_data.count(), 1)
    else:
        avg_ph = 0.0
        avg_humidity = 0.0

    return render(request, 'dashboard/api_soil_data_table.html', {
        'api_soil_data': api_soil_data,
        'is_admin': is_admin,
        'avg_ph': avg_ph,
        'avg_humidity': avg_humidity,
    })

@login_required(login_url='dashboard_login')
def export_api_soil_data_csv(request):
    """Export API soil data to CSV"""
    is_admin = request.user.role == 'admin' or request.user.is_staff

    if is_admin:
        api_soil_data = APISoilData.objects.select_related('user').all().order_by('-created_at')
    else:
        api_soil_data = APISoilData.objects.select_related('user').filter(user=request.user).order_by('-created_at')

    response = HttpResponse(content_type='text/csv')
    response['Content-Disposition'] = 'attachment; filename="api_soil_data_report.csv"'

    writer = csv.writer(response)
    writer.writerow(['ID', 'User', 'Nitrogen', 'Phosphorus', 'Potassium', 'Temperature', 'Humidity', 'pH', 'Prediction', 'Confidence', 'Created At'])

    for data in api_soil_data:
        writer.writerow([
            data.id,
            data.user.username if data.user else 'N/A',
            data.nitrogen,
            data.phosphorus,
            data.potassium,
            data.temperature,
            data.humidity,
            data.ph,
            data.prediction,
            data.confidence,
            data.created_at.strftime('%Y-%m-%d %H:%M:%S')
        ])

    return response

@login_required(login_url='dashboard_login')
def export_api_soil_data_pdf(request):
    """Export API soil data to PDF"""
    is_admin = request.user.role == 'admin' or request.user.is_staff

    if is_admin:
        api_soil_data = APISoilData.objects.select_related('user').all().order_by('-created_at')
    else:
        api_soil_data = APISoilData.objects.select_related('user').filter(user=request.user).order_by('-created_at')

    response = HttpResponse(content_type='application/pdf')
    response['Content-Disposition'] = 'attachment; filename="api_soil_data_report.pdf"'

    doc = SimpleDocTemplate(response, pagesize=letter)
    elements = []

    styles = getSampleStyleSheet()
    title = Paragraph("API Soil Data Report", styles['Title'])
    elements.append(title)

    # Summary
    total_records = api_soil_data.count()
    summary_text = f"Total Records: {total_records}"
    if total_records > 0:
        avg_ph = round(sum(data.ph for data in api_soil_data) / total_records, 2)
        avg_humidity = round(sum(data.humidity for data in api_soil_data) / total_records, 2)
        summary_text += f"<br/>Average pH: {avg_ph}<br/>Average Humidity: {avg_humidity}"

    summary = Paragraph(summary_text, styles['Normal'])
    elements.append(summary)

    # Table data
    data = [['ID', 'User', 'N', 'P', 'K', 'Temp', 'Humidity', 'pH', 'Prediction', 'Confidence', 'Created']]

    for item in api_soil_data:
        data.append([
            str(item.id),
            item.user.username if item.user else 'N/A',
            str(item.nitrogen),
            str(item.phosphorus),
            str(item.potassium),
            str(item.temperature),
            str(item.humidity),
            str(item.ph),
            item.prediction or 'N/A',
            str(item.confidence) if item.confidence else 'N/A',
            item.created_at.strftime('%Y-%m-%d %H:%M')
        ])

    table = Table(data)
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 14),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
        ('GRID', (0, 0), (-1, -1), 1, colors.black)
    ]))

    elements.append(table)
    doc.build(elements)

    return response

@login_required(login_url='dashboard_login')
def soil_parameter_trends(request):
    """API endpoint to fetch soil parameter trends data for charts"""
    is_admin = request.user.role == 'admin' or request.user.is_staff

    # Get parameters to display from request (handle comma-separated string)
    params_str = request.GET.get('params', 'temperature,humidity,ph')
    parameters = [p.strip() for p in params_str.split(',') if p.strip()]
    days = int(request.GET.get('days', 30))  # Default to last 30 days

    # Calculate date range
    from django.utils import timezone
    from datetime import timedelta
    end_date = timezone.now()
    start_date = end_date - timedelta(days=days)

    # Fetch data
    if is_admin:
        soil_data = APISoilData.objects.filter(created_at__gte=start_date).order_by('created_at')
    else:
        soil_data = APISoilData.objects.filter(user=request.user, created_at__gte=start_date).order_by('created_at')

    # Prepare data for Chart.js
    datasets = {}

    # Initialize datasets for each parameter
    param_config = {
        'temperature': {'label': 'Temperature (°C)', 'color': 'rgba(255, 99, 132, 1)', 'bgColor': 'rgba(255, 99, 132, 0.2)'},
        'humidity': {'label': 'Humidity (%)', 'color': 'rgba(54, 162, 235, 1)', 'bgColor': 'rgba(54, 162, 235, 0.2)'},
        'ph': {'label': 'pH Level', 'color': 'rgba(75, 192, 192, 1)', 'bgColor': 'rgba(75, 192, 192, 0.2)'},
        'nitrogen': {'label': 'Nitrogen (mg/kg)', 'color': 'rgba(153, 102, 255, 1)', 'bgColor': 'rgba(153, 102, 255, 0.2)'},
        'phosphorus': {'label': 'Phosphorus (mg/kg)', 'color': 'rgba(255, 159, 64, 1)', 'bgColor': 'rgba(255, 159, 64, 0.2)'},
        'potassium': {'label': 'Potassium (mg/kg)', 'color': 'rgba(255, 205, 86, 1)', 'bgColor': 'rgba(255, 205, 86, 0.2)'},
        'rainfall': {'label': 'Rainfall (mm)', 'color': 'rgba(201, 203, 207, 1)', 'bgColor': 'rgba(201, 203, 207, 0.2)'},
    }

    for param in parameters:
        if param in param_config:
            datasets[param] = {
                'label': param_config[param]['label'],
                'data': [],
                'borderColor': param_config[param]['color'],
                'backgroundColor': param_config[param]['bgColor'],
                'tension': 0.4,
                'fill': False,
            }

    # Process data points
    for data in soil_data:
        timestamp = data.created_at.strftime('%Y-%m-%d %H:%M')

        for param in parameters:
            if param in datasets:
                value = getattr(data, param, None)
                # Create data point with additional info for tooltips
                data_point = {
                    'x': timestamp,
                    'y': float(value) if value is not None else None,
                    'crop': data.prediction or 'N/A',
                    'nitrogen': data.nitrogen,
                    'phosphorus': data.phosphorus,
                    'potassium': data.potassium,
                    'time': data.created_at.strftime('%Y-%m-%d %H:%M:%S')
                }
                datasets[param]['data'].append(data_point)

    # Sort data points by time for each dataset
    for param in datasets:
        datasets[param]['data'].sort(key=lambda dp: dp['time'])

    # Prepare response data
    chart_data = {
        'datasets': list(datasets.values())
    }

    from django.http import JsonResponse
    return JsonResponse(chart_data)
