from django.contrib.auth.backends import ModelBackend
from django.contrib.auth import get_user_model

User = get_user_model()

class UsernameOrEmailBackend(ModelBackend):
    """
    Custom authentication backend that allows login with username or email
    """
    
    def authenticate(self, request, username=None, password=None, **kwargs):
        if username is None or password is None:
            return None
        
        # Try to find user by username first
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            # If not found by username, try email
            try:
                user = User.objects.get(email=username)
            except User.DoesNotExist:
                return None
        
        # Check if the user can authenticate
        if user.check_password(password) and self.user_can_authenticate(user):
            return user
        return None
    
    def user_can_authenticate(self, user):
        """
        Reject users with is_active=False. Custom user models that don't have
        that attribute are allowed.
        """
        is_active = getattr(user, 'is_active', None)
        return is_active or is_active is None
