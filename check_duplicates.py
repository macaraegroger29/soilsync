#!/usr/bin/env python3
"""
Script to check for duplicate users in the database
"""

import os
import sys
import django

# Add the backend directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), 'soilsync_backend'))

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'soilsync_backend.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

def check_duplicates():
    """Check for duplicate users in the database"""
    print("=== Checking for Duplicate Users ===\n")
    
    # Check for duplicate usernames
    print("Checking for duplicate usernames...")
    usernames = User.objects.values_list('username', flat=True)
    username_counts = {}
    for username in usernames:
        username_counts[username] = username_counts.get(username, 0) + 1
    
    duplicate_usernames = {username: count for username, count in username_counts.items() if count > 1}
    if duplicate_usernames:
        print("❌ Found duplicate usernames:")
        for username, count in duplicate_usernames.items():
            print(f"   {username}: {count} instances")
    else:
        print("✅ No duplicate usernames found")
    
    print()
    
    # Check for duplicate emails
    print("Checking for duplicate emails...")
    emails = User.objects.values_list('email', flat=True)
    email_counts = {}
    for email in emails:
        if email:  # Skip empty emails
            email_counts[email] = email_counts.get(email, 0) + 1
    
    duplicate_emails = {email: count for email, count in email_counts.items() if count > 1}
    if duplicate_emails:
        print("❌ Found duplicate emails:")
        for email, count in duplicate_emails.items():
            print(f"   {email}: {count} instances")
            # Show the users with this email
            users = User.objects.filter(email=email)
            for user in users:
                print(f"     - User ID: {user.id}, Username: {user.username}, Created: {user.date_joined}")
    else:
        print("✅ No duplicate emails found")
    
    print()
    
    # Show all users
    print("=== All Users in Database ===")
    users = User.objects.all().order_by('date_joined')
    for user in users:
        print(f"ID: {user.id}, Username: {user.username}, Email: {user.email}, Role: {user.role}, Created: {user.date_joined}")
    
    return duplicate_usernames, duplicate_emails

def clean_duplicates():
    """Clean up duplicate users (keep the oldest one)"""
    print("\n=== Cleaning Duplicate Users ===")
    
    # Clean duplicate emails
    emails = User.objects.values_list('email', flat=True).distinct()
    for email in emails:
        if email:  # Skip empty emails
            users_with_email = User.objects.filter(email=email).order_by('date_joined')
            if users_with_email.count() > 1:
                print(f"Found {users_with_email.count()} users with email: {email}")
                # Keep the oldest user, delete the rest
                oldest_user = users_with_email.first()
                users_to_delete = users_with_email.exclude(id=oldest_user.id)
                
                print(f"Keeping user: {oldest_user.username} (ID: {oldest_user.id})")
                for user in users_to_delete:
                    print(f"Deleting user: {user.username} (ID: {user.id})")
                    user.delete()
    
    print("✅ Duplicate cleanup completed")

if __name__ == "__main__":
    duplicates = check_duplicates()
    
    if duplicates[0] or duplicates[1]:
        print("\n⚠️  Duplicates found!")
        response = input("Do you want to clean up duplicates? (y/N): ")
        if response.lower() == 'y':
            clean_duplicates()
            print("\n=== Re-checking after cleanup ===")
            check_duplicates()
    else:
        print("\n✅ No duplicates found. Database is clean!")
