import csv
from django.core.management.base import BaseCommand
from api.models import Dataset
from pathlib import Path

class Command(BaseCommand):
    help = 'Import soil dataset from CSV file'

    def add_arguments(self, parser):
        parser.add_argument('csv_file', type=str, help='Path to the CSV file')

    def handle(self, *args, **options):
        csv_file = options['csv_file']
        file_path = Path(csv_file)

        if not file_path.exists():
            self.stdout.write(self.style.ERROR(f'File {csv_file} does not exist'))
            return

        try:
            # Clear existing data
            Dataset.objects.all().delete()
            self.stdout.write(self.style.SUCCESS('Cleared existing dataset'))

            # Read and import CSV data
            with open(file_path, 'r') as f:
                reader = csv.DictReader(f)
                datasets = []
                for row in reader:
                    dataset = Dataset(
                        nitrogen=float(row['N']),
                        phosphorus=float(row['P']),
                        potassium=float(row['K']),
                        temperature=float(row['temperature']),
                        humidity=float(row['humidity']),
                        ph=float(row['ph']),
                        rainfall=float(row['rainfall']),
                        label=row['label']
                    )
                    datasets.append(dataset)

                # Bulk create for better performance
                Dataset.objects.bulk_create(datasets)
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Successfully imported {len(datasets)} records from {csv_file}'
                    )
                )

        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Error importing dataset: {str(e)}')
            ) 