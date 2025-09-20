import csv
from django.core.management.base import BaseCommand
from dashboard.models import SoilData, SensorDevice
from django.contrib.auth.models import User
from django.utils import timezone

class Command(BaseCommand):
    help = 'Import soil data from a CSV file into the SoilData model.'

    def add_arguments(self, parser):
        parser.add_argument('csv_path', type=str, help='Path to the CSV file to import.')

    def handle(self, *args, **options):
        csv_path = options['csv_path']
        user = User.objects.first()
        sensor = SensorDevice.objects.first()
        if not user or not sensor:
            self.stdout.write(self.style.ERROR('At least one user and one sensor must exist.'))
            return
        count = 0
        with open(csv_path, newline='') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                SoilData.objects.create(
                    user=user,
                    sensor=sensor,
                    location=row.get('location', ''),
                    nitrogen=row.get('N', 0),
                    phosphorus=row.get('P', 0),
                    potassium=row.get('K', 0),
                    ph_level=row.get('ph', 0),
                    moisture=row.get('moisture', 0),
                    temperature=row.get('temperature', 0),
                    rainfall=row.get('rainfall', 0),
                    crop=row.get('label', ''),
                    timestamp=timezone.now()
                )
                count += 1
        self.stdout.write(self.style.SUCCESS(f'Imported {count} soil data records from {csv_path}')) 