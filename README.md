# Smart Glasses for the Blind - AI-Powered Demand Prediction System

## Mission Statement
Developing AI-powered smart glasses that serve as "eyes for the blind" using real-time object detection, navigation assistance, and voice-guided instructions to help visually impaired individuals navigate independently.

## Project Overview
This project predicts market demand for smart glasses based on assistive technology training availability globally. The system uses machine learning to analyze training coverage across different categories (cognition, communication, hearing, mobility, self-care, and vision) to determine optimal manufacturing and distribution strategies.

## 🏗️ Project Structure

```
linear_regression_model/
│
├── summative/
│   ├── linear_regression/
│   │   ├── multivariate.ipynb          # ML model training notebook
│   │   ├── data/
│   │   │   └── assistive_tech_data.csv # Training dataset
│   │   └── models/
│   │       ├── best_smart_glasses_model.pkl  # Trained model
│   │       └── feature_scaler.pkl            # Feature scaler
│   ├── API/
│   │   ├── prediction.py               # FastAPI application
│   │   ├── requirements.txt            # Python dependencies
│   │   └── models/
│   │       ├── best_smart_glasses_model.pkl
│   │       └── feature_scaler.pkl
│   └── FlutterApp/
│       ├── lib/
│       │   ├── main.dart              # App entry point
│       │   ├── screens/
│       │   │   ├── home_screen.dart   # Welcome screen
│       │   │   └── prediction_screen.dart # Prediction interface
│       │   └── services/
│       │       └── api_service.dart   # API communication
│       ├── pubspec.yaml               # Flutter dependencies
│       └── android/                   # Android configuration
```

## 🚀 Getting Started

### Prerequisites
- **Python 3.8+**
- **Flutter SDK 3.0+**
- **Git**
- **Android Studio** (for mobile app testing)

### 1. Clone the Repository
```bash
git clone https://github.com/Stecie06/smart-glasses-prediction.git
cd smart-glasses-prediction
```

### 2. Set Up Python Environment
```bash
# Create virtual environment
python -m venv smart_glasses_env

# Activate environment
# Windows:
smart_glasses_env\Scripts\activate
# macOS/Linux:
source smart_glasses_env/bin/activate

# Install dependencies
cd API
pip install -r requirements.txt
```

### 3. Train the Model
```bash
cd ../linear_regression
# Run the Jupyter notebook or convert to Python script
jupyter notebook multivariate.ipynb
# Or run as Python script:
python multivariate.py
```

### 4. Run the API Locally
```bash
cd API && uvicorn prediction:app --host 0.0.0.0 --port $PORT
```
The API will be available at: `http://localhost:8000`
- Swagger UI: `https://smart-glasses-prediction.onrender.com/docs`

### 5. Set Up Flutter App
```bash
cd ../flutterapp
flutter pub get
flutter run
```

## 📱 Mobile App Setup

### Android Setup
1. Ensure Android SDK is installed
2. Connect Android device or start emulator
3. Run: `flutter run`

## 🧪 Testing the System

### API Testing
```bash
# Health check
curl https://smart-glasses-prediction.onrender.com/health

# Prediction test
curl -X POST "https://smart-glasses-prediction.onrender.com//predict" \
     -H "Content-Type: application/json" \
     -d '{
       "cognition": 1,
       "communication": 1,
       "hearing": 1,
       "mobility": 0,
       "self_care": 1,
       "vision": 0
     }'
```

### Mobile App Testing
1. Open the app
2. Navigate to the prediction screen
3. Toggle training availability options
4. Tap "Predict Demand."
5. Verify results display correctly

## 📊 Model Performance

### Best Model: Random Forest Regressor
- **Test R² Score**: 0.8542
- **Test MSE**: 0.1247
- **Features**: 9 engineered features, including training availability and composite scores

### Feature Importance
1. **Vision Training** (Most Important)
2. **Total Training Score**
3. **Vision-Mobility Score**
4. **Assistive Tech Readiness**
5. **Mobility Training**
6. **Other training categories**

## 🔧 API Endpoints

### Core Endpoints
- `GET /` - API information
- `GET /health` - Health check
- `POST /predict` - Single prediction
- `POST /predict-batch` - Batch predictions
- `GET /model-info` - Model information

### Request Format
```json
{
  "cognition": 0,      // 0=No, 1=Yes
  "communication": 1,
  "hearing": 1,
  "mobility": 0,
  "self_care": 1,
  "vision": 0
}
```

### Response Format
```json
{
  "demand_score": 2,
  "demand_level": "Medium",
  "confidence": 0.847,
  "input_summary": {
    "total_training_areas": 3,
    "vision_training_available": false,
    "training_coverage_percentage": 50.0
  },
  "recommendations": "Moderate demand expected. Consider targeted marketing."
}
```

## 🎯 Key Features

### Machine Learning Model
- ✅ Linear Regression with Gradient Descent
- ✅ Scikit-learn implementations
- ✅ Decision Tree and Random Forest comparison
- ✅ Feature engineering and standardization
- ✅ Model performance visualization

### FastAPI Backend
- ✅ CORS middleware enabled
- ✅ Pydantic data validation
- ✅ Range constraints (0-1 for all inputs)
- ✅ Error handling and logging
- ✅ Swagger UI documentation

### Flutter Mobile App
- ✅ Beautiful, intuitive UI
- ✅ Multi-screen navigation
- ✅ Real-time form validation
- ✅ Loading states and error handling
- ✅ Animated transitions
- ✅ Comprehensive result display

## 🚨 Common Issues & Solutions

### API Issues
- **Model files not found**: Ensure `.pkl` files are in the API directory
- **CORS errors**: Verify CORS middleware is properly configured
- **Deployment failures**: Check Python version and dependencies

### Flutter Issues
- **Network errors**: Update API URL in `api_service.dart`
- **Build failures**: Run `flutter clean` and `flutter pub get`
- **Emulator issues**: Restart emulator or use physical device

## 📈 Business Impact

### Demand Prediction Insights
- **High Demand Regions**: Countries with limited vision training coverage
- **Low Demand Regions**: Countries with comprehensive assistive technology programs
- **Market Opportunities**: Focus on regions with medium demand for optimal ROI

### Manufacturing Recommendations
- Prioritize high-demand regions for initial production
- Develop partnerships in medium-demand areas
- Create awareness programs in low-demand regions

## 🎬 Video Demo Requirements

### 5-Minute Demo Structure:
1. **Model Performance** (1 min) - Show notebook results and comparison
2. **API Testing** (1.5 min) - Demonstrate Swagger UI and various inputs
3. **Mobile App Demo** (2 min) - Show app navigation and predictions
4. **Code Walkthrough** (0.5 min) - Highlight key implementation details

### Demo Checklist:
- ✅ Camera on throughout demo
- ✅ Test various input combinations
- ✅ Show data type and range validation
- ✅ Demonstrate error handling
- ✅ Explain model selection rationale

## 🔗 Links

- **API Documentation**: (https://smart-glasses-prediction.onrender.com/docs)
- **YouTube Demo**: (https://www.youtube.com/watch?v=AlLfr5EeO6M)

## 👥 Contributing

This project is part of a machine learning assignment focusing on assistive technology for visually impaired individuals. The goal is to create a complete ML pipeline from data analysis to mobile deployment.

## 📄 License

This project is created for educational purposes as part of a machine learning course assignment.

---

**Built with ❤️ by Stecie**
