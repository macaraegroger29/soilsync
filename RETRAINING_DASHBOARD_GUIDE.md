# SoilSync Model Retraining Dashboard

## Overview

The Model Retraining Dashboard is a comprehensive tool for managing machine learning model training, versioning, and deployment in SoilSync. It provides a complete workflow from data collection to model deployment with detailed performance metrics and visualizations.

## Features

### 1. Upload / Add Data
- **CSV Import**: Upload new soil sensor data via CSV files
- **Merge Options**: Choose to merge with existing data or replace it entirely
- **Data Validation**: Automatic validation of required columns (N, P, K, temperature, humidity, ph, rainfall, label)
- **Progress Tracking**: Real-time feedback on upload status

### 2. Retrain Model
- **One-Click Training**: Trigger model retraining with current dataset
- **Automatic Metrics**: Calculate accuracy, precision, recall, and F1-score
- **Model Versioning**: Automatic versioning with timestamps
- **Performance Tracking**: Store detailed training metrics and logs

### 3. Training Results Panel
- **Performance Metrics**: Display accuracy, precision, recall, and F1-score
- **Confusion Matrix**: Visual representation of model performance
- **Feature Importance**: Bar charts showing which features matter most
- **Training Progress**: Line charts showing training vs validation accuracy
- **Model Comparison**: Compare different model versions

### 4. Versioning & Logs
- **Model History**: Track all trained model versions
- **Performance Comparison**: Compare metrics across versions
- **Training Logs**: Detailed logs of training parameters and results
- **Deployment Status**: Track which model is currently active

### 5. Deployment System
- **Model Deployment**: Deploy any version as the active model
- **Automatic Switching**: Seamlessly switch between model versions
- **Rollback Capability**: Revert to previous model versions if needed

## How to Use

### Step 1: Access the Dashboard
1. Open the SoilSync app
2. Navigate to the main dashboard
3. Click the "Retraining" button in the app bar

### Step 2: Upload New Data
1. Click "Import CSV" button
2. Select your CSV file with soil sensor data
3. Choose merge mode:
   - **Merge**: Add to existing dataset
   - **Replace**: Replace entire dataset
4. Click "Upload" to process the data

### Step 3: Retrain the Model
1. Click "Retrain Model" button
2. Wait for training to complete (progress indicator shown)
3. View detailed results and metrics

### Step 4: Review Results
The dashboard will display:
- **Performance Metrics**: Accuracy, precision, recall, F1-score
- **Confusion Matrix**: Visual performance breakdown
- **Feature Importance**: Which soil parameters matter most
- **Training Progress**: How the model learned over time

### Step 5: Deploy Model (Optional)
1. Review the model performance
2. If satisfied, click "Deploy" on the desired version
3. The model becomes active for predictions

## Data Format Requirements

### CSV File Format
Your CSV file must contain these exact columns:
```
N,P,K,temperature,humidity,ph,rainfall,label
```

### Example CSV Data
```csv
N,P,K,temperature,humidity,ph,rainfall,label
90,42,43,20.87974371,82.00274423,6.502985292,202.9355362,rice
85,58,41,21.77046169,80.31964408,7.038096361,226.6555374,rice
60,55,44,23.00445915,82.3207629,7.840207144,263.9642476,rice
74,35,40,26.49109635,80.15836264,6.980400905,242.8640342,rice
78,42,42,20.13017547,81.60487384,7.628472891,262.7173401,rice
```

## Understanding the Results

### Performance Metrics
- **Accuracy**: Overall correctness of predictions (0-100%)
- **Precision**: How many predicted crops were correct
- **Recall**: How many actual crops were found
- **F1-Score**: Balanced measure of precision and recall

### Confusion Matrix
- Shows actual vs predicted crop classifications
- Diagonal values = correct predictions
- Off-diagonal values = misclassifications
- Color coding indicates prediction frequency

### Feature Importance
- Shows which soil parameters are most important for predictions
- Higher percentages = more important features
- Helps understand what drives crop recommendations

### Training Progress
- Shows how model accuracy improved during training
- Training vs validation accuracy comparison
- Helps identify overfitting or underfitting

## Best Practices

### Data Collection
1. **Consistent Measurements**: Use calibrated sensors
2. **Complete Records**: Ensure all parameters are measured
3. **Label Accuracy**: Verify crop labels are correct
4. **Regular Updates**: Add new data regularly for better models

### Model Training
1. **Sufficient Data**: Collect at least 100+ records per crop
2. **Balanced Dataset**: Ensure equal representation of crops
3. **Quality Control**: Review data before training
4. **Regular Retraining**: Retrain when adding significant new data

### Model Deployment
1. **Performance Review**: Check metrics before deploying
2. **A/B Testing**: Test new models with small user groups
3. **Rollback Plan**: Keep previous versions available
4. **Monitoring**: Track model performance after deployment

## Troubleshooting

### Common Issues

#### Upload Failures
- **Check CSV Format**: Ensure correct column names
- **File Size**: Large files may take time to process
- **Network Issues**: Check internet connection

#### Training Failures
- **Insufficient Data**: Need at least some records to train
- **Data Quality**: Check for missing or invalid values
- **Server Issues**: Try again if backend is busy

#### Performance Issues
- **Low Accuracy**: May need more training data
- **Overfitting**: Model too complex for available data
- **Underfitting**: Model too simple, needs more features

### Getting Help
1. Check the error messages in the dashboard
2. Verify your data format matches requirements
3. Ensure you have sufficient data for training
4. Contact support if issues persist

## API Endpoints

The dashboard uses these backend endpoints:

- `GET /api/models/` - List all model versions
- `GET /api/models/{id}/` - Get model details
- `POST /api/models/{id}/deploy/` - Deploy model version
- `POST /api/retrain/` - Retrain model
- `POST /api/upload-csv/` - Upload CSV data

## Security Notes

- All operations require authentication
- Only admin users can access retraining features
- Model files are stored securely on the server
- Training logs are preserved for audit purposes

## Future Enhancements

- **Automated Retraining**: Schedule regular model updates
- **A/B Testing**: Compare model versions with real users
- **Advanced Metrics**: Additional performance indicators
- **Data Visualization**: Enhanced charts and graphs
- **Export Features**: Download training reports and logs
