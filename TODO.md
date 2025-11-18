# TODO: Add Dynamic Graph for Soil Parameter Trends

## Overview
Create a dynamic graph on the Django dashboard to visualize trends in soil parameters (moisture, pH, temperature, etc.) over time with timestamps.

## Steps
- [x] Add view function in dashboard/views.py for fetching historical soil data
- [x] Add URL pattern in dashboard/urls.py for the trends endpoint
- [x] Modify database_dashboard.html to include parameter trends chart section
- [ ] Test the chart with sample data
- [x] Add parameter selection controls (checkboxes for which parameters to show)
- [x] Ensure proper date formatting for x-axis
- [x] Handle cases with no data or limited data points
