import csv
from django.core.management.base import BaseCommand
from dashboard.models import SoilData, SensorDevice
from django.contrib.auth.models import User
from django.utils import timezone

class Command(BaseCommand):
    help = 'Import soil data from a CSV file into the SoilData model.'

    def add_arguments(self, parser):
        parser.add_argument('csv_path', type=str, help='Path to the CSV file to import.')
        parser.add_argument('--model', type=str, choices=['SoilData', 'Dataset'], default='Dataset', help='Model to import data into (SoilData or Dataset). Default: Dataset')

    def handle(self, *args, **options):
        csv_path = options['csv_path']
        model_choice = options['model']
        count = 0
        if model_choice == 'SoilData':
            from dashboard.models import SoilData, SensorDevice
            from django.contrib.auth.models import User
            from django.utils import timezone
            user = User.objects.first()
            sensor = SensorDevice.objects.first()
            if not user or not sensor:
                self.stdout.write(self.style.ERROR('At least one user and one sensor must exist.'))
                return
        with open(csv_path, newline='') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if model_choice == 'SoilData':
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
                else:  # Dataset
                    from api.models import Dataset
                    Dataset.objects.create(
                        nitrogen=row.get('N', 0),
                        phosphorus=row.get('P', 0),
                        potassium=row.get('K', 0),
                        temperature=row.get('temperature', 0),
                        humidity=row.get('humidity', 0),
                        ph=row.get('ph', 0),
                        rainfall=row.get('rainfall', 0),
                        label=row.get('label', '')
                    )
                count += 1
        self.stdout.write(self.style.SUCCESS(f'Imported {count} records into {model_choice} from {csv_path}')) 