from django.core.management.base import BaseCommand
from dashboard.models import SoilData, CropRecommendation
from dashboard.services.crop_recommendation_service import CropRecommendationService

class Command(BaseCommand):
    help = 'Generate crop recommendations for existing soil data'

    def add_arguments(self, parser):
        parser.add_argument(
            '--soil-id',
            type=int,
            help='Generate recommendation for specific soil data ID'
        )
        parser.add_argument(
            '--all',
            action='store_true',
            help='Generate recommendations for all soil data without recommendations'
        )

    def handle(self, *args, **options):
        service = CropRecommendationService()
        
        if options['soil_id']:
            # Process specific soil data
            try:
                soil_data = SoilData.objects.get(id=options['soil_id'])
                recommendation = service.generate_recommendations(soil_data.id)
                if recommendation:
                    self.stdout.write(
                        self.style.SUCCESS(
                            f"Generated recommendation for soil data ID {options['soil_id']}: {recommendation.crop_name}"
                        )
                    )
                else:
                    self.stdout.write(
                        self.style.WARNING(
                            f"No recommendation generated for soil data ID {options['soil_id']}"
                        )
                    )
            except SoilData.DoesNotExist:
                self.stdout.write(
                    self.style.ERROR(
                        f"Soil data ID {options['soil_id']} not found"
                    )
                )
        
        elif options['all']:
            # Process all soil data without recommendations
            soil_data_list = SoilData.objects.filter(
                croprecommendation__isnull=True
            ).order_by('-timestamp')
            
            count = 0
            for soil_data in soil_data_list:
                recommendation = service.generate_recommendations(soil_data.id)
                if recommendation:
                    count += 1
                    self.stdout.write(
                        self.style.SUCCESS(
                            f"Generated recommendation for soil data ID {soil_data.id}: {recommendation.crop_name}"
                        )
                    )
            
            self.stdout.write(
                self.style.SUCCESS(
                    f"Generated {count} new crop recommendations"
                )
            )
        
        else:
            # Process all soil data
            soil_data_list = SoilData.objects.all().order_by('-timestamp')
            count = 0
            for soil_data in soil_data_list:
                # Check if recommendation already exists
                existing = CropRecommendation.objects.filter(soil_data=soil_data).first()
                if not existing:
                    recommendation = service.generate_recommendations(soil_data.id)
                    if recommendation:
                        count += 1
                        self.stdout.write(
                            self.style.SUCCESS(
                                f"Generated recommendation for soil data ID {soil_data.id}: {recommendation.crop_name}"
                            )
                        )
            
            self.stdout.write(
                self.style.SUCCESS(
                    f"Generated {count} new crop recommendations"
                )
            )
