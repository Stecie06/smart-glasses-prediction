from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, field_validator
import joblib
import numpy as np
import pandas as pd
import uvicorn
from typing import Dict, Any, List
import os
from contextlib import asynccontextmanager

# Lifespan handler for model loading
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Load models at startup
    global model, scaler, actual_feature_names
    try:
        model = joblib.load('models/best_smart_glasses_model.pkl')
        scaler = joblib.load('models/feature_scaler.pkl')
        
        # Get the actual feature names used during training
        if hasattr(model, 'feature_names_in_'):
            actual_feature_names = list(model.feature_names_in_)
            print(f"✅ Model expects these features: {actual_feature_names}")
        elif hasattr(scaler, 'feature_names_in_'):
            actual_feature_names = list(scaler.feature_names_in_)
            print(f"✅ Scaler expects these features: {actual_feature_names}")
        else:
            # Based on your dataset, these are the exact column names
            actual_feature_names = [
                'Training related to Cognition',
                'Training related to Communication', 
                'Training related to Hearing',
                'Training related to Mobility',
                'Training related to Self-care',
                'Training related to Vision',
                'total_training_score',
                'vision_mobility_score', 
                'assistive_tech_readiness'
            ]
            print(f"⚠️ Using fallback feature names: {actual_feature_names}")
        
        print("✅ Model and scaler loaded successfully!")
        
    except Exception as e:
        print(f"❌ Error loading model files: {e}")
        print("⚠️ API will run in demo mode without actual predictions")
        actual_feature_names = [
            'Training related to Cognition',
            'Training related to Communication', 
            'Training related to Hearing',
            'Training related to Mobility',
            'Training related to Self-care',
            'Training related to Vision',
            'total_training_score',
            'vision_mobility_score', 
            'assistive_tech_readiness'
        ]
    
    yield  # App runs here
    
    # Cleanup can go here if needed
    print("🚪 Shutting down...")

# Initialize FastAPI app with lifespan
app = FastAPI(
    title="Smart Glasses Demand Prediction API",
    description="AI-powered API to predict demand for smart glasses based on assistive technology training availability",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables for model and scaler
model = None
scaler = None
actual_feature_names = None

# Pydantic models for request validation
class PredictionRequest(BaseModel):
    cognition: int = Field(..., ge=0, le=1, description="Training available for cognition (0=No, 1=Yes)")
    communication: int = Field(..., ge=0, le=1, description="Training available for communication (0=No, 1=Yes)")
    hearing: int = Field(..., ge=0, le=1, description="Training available for hearing (0=No, 1=Yes)")
    mobility: int = Field(..., ge=0, le=1, description="Training available for mobility (0=No, 1=Yes)")
    self_care: int = Field(..., ge=0, le=1, description="Training available for self-care (0=No, 1=Yes)")
    vision: int = Field(..., ge=0, le=1, description="Training available for vision (0=No, 1=Yes)")

    @field_validator('cognition', 'communication', 'hearing', 'mobility', 'self_care', 'vision')
    @classmethod
    def validate_binary_values(cls, v):
        if v not in [0, 1]:
            raise ValueError('Value must be 0 (No) or 1 (Yes)')
        return v

    model_config = {
        "json_schema_extra": {
            "example": {
                "cognition": 1,
                "communication": 1,
                "hearing": 1,
                "mobility": 0,
                "self_care": 1,
                "vision": 0
            }
        }
    }

class PredictionResponse(BaseModel):
    demand_score: int = Field(..., description="Smart glasses demand score (1=Low, 2=Medium, 3=High)")
    demand_level: str = Field(..., description="Human-readable demand level")
    confidence: float = Field(..., description="Model confidence score (0-1)")
    input_summary: Dict[str, Any] = Field(..., description="Summary of input features")
    recommendations: str = Field(..., description="Business recommendations based on prediction")

def get_demand_interpretation(score: int) -> tuple:
    """Convert numerical demand score to human-readable level and recommendations"""
    if score == 1:
        return "Low", "Market shows low demand. Focus on awareness and education programs."
    elif score == 2:
        return "Medium", "Moderate demand expected. Consider targeted marketing and partnerships."
    else:
        return "High", "High demand potential! Prioritize manufacturing and distribution in this region."

def predict_smart_glasses_demand(features: dict) -> tuple:
    """
    Predict smart glasses demand based on assistive technology training availability
    Returns: (demand_score, confidence)
    """
    global model, scaler, actual_feature_names
    
    if model is None or scaler is None:
        # Demo mode - return mock prediction based on total training areas
        total_score = sum(features.values())
        demo_score = min(3, max(1, 1 + (total_score // 2)))
        return demo_score, 0.75
    
    try:
        # Calculate engineered features
        total_training_score = sum(features.values())
        vision_mobility_score = features['vision'] + features['mobility']
        assistive_tech_readiness = (total_training_score / 6) * 100
        
        # Create feature dictionary with exact names from training
        feature_data = {
            'Training related to Cognition': features['cognition'],
            'Training related to Communication': features['communication'],
            'Training related to Hearing': features['hearing'],
            'Training related to Mobility': features['mobility'],
            'Training related to Self-care': features['self_care'],
            'Training related to Vision': features['vision'],
            'total_training_score': total_training_score,
            'vision_mobility_score': vision_mobility_score,
            'assistive_tech_readiness': assistive_tech_readiness
        }
        
        # Create DataFrame with features in the exact order expected by the model
        features_df = pd.DataFrame([feature_data])
        
        # Ensure we have all the features the model expects
        for feature_name in actual_feature_names:
            if feature_name not in features_df.columns:
                print(f"⚠️ Missing feature: {feature_name}")
                features_df[feature_name] = 0  # Default value
        
        # Reorder columns to match training order
        features_df = features_df[actual_feature_names]
        
        print(f"🔍 Feature DataFrame shape: {features_df.shape}")
        print(f"🔍 Feature DataFrame columns: {list(features_df.columns)}")
        print(f"🔍 Feature values: {features_df.iloc[0].to_dict()}")
        
        # Scale features
        features_scaled = scaler.transform(features_df)
        
        # Make prediction
        prediction = model.predict(features_scaled)[0]
        demand_score = max(1, min(3, round(prediction)))
        confidence = min(0.95, max(0.60, 1 - abs(prediction - demand_score)))
        
        return demand_score, confidence
        
    except Exception as e:
        print(f"❌ Prediction error: {str(e)}")
        print(f"🔍 Expected features: {actual_feature_names}")
        print(f"🔍 Provided features: {list(feature_data.keys())}")
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

# API Endpoints
@app.get("/")
async def root():
    return {
        "message": "Smart Glasses Demand Prediction API",
        "mission": "AI-powered smart glasses for the blind",
        "version": "1.0.0",
        "status": "Model loaded" if model is not None else "Demo mode",
        "endpoints": {
            "predict": "/predict",
            "predict-batch": "/predict-batch",
            "health": "/health",
            "model-info": "/model-info",
            "docs": "/docs"
        }
    }

@app.get("/health")
async def health_check():
    global model, scaler
    try:
        test_features = {
            'cognition': 1, 'communication': 1, 'hearing': 1,
            'mobility': 1, 'self_care': 1, 'vision': 1
        }
        test_prediction = predict_smart_glasses_demand(test_features)
        
        return {
            "status": "healthy",
            "model_loaded": model is not None and scaler is not None,
            "test_prediction_successful": True,
            "demo_mode": model is None or scaler is None,
            "test_result": {
                "demand_score": test_prediction[0],
                "confidence": round(test_prediction[1], 3)
            }
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "model_loaded": False,
            "error": str(e)
        }

@app.post("/predict", response_model=PredictionResponse)
async def predict_demand(request: PredictionRequest):
    """
    Predict smart glasses demand based on assistive technology training availability
    """
    try:
        features = {
            'cognition': request.cognition,
            'communication': request.communication,
            'hearing': request.hearing,
            'mobility': request.mobility,
            'self_care': request.self_care,
            'vision': request.vision
        }
        
        print(f"🔍 Received prediction request: {features}")
        
        demand_score, confidence = predict_smart_glasses_demand(features)
        demand_level, recommendations = get_demand_interpretation(demand_score)
        
        input_summary = {
            "total_training_areas": sum(features.values()),
            "vision_training_available": bool(features['vision']),
            "mobility_training_available": bool(features['mobility']),
            "training_coverage_percentage": round((sum(features.values()) / 6) * 100, 1)
        }
        
        response = PredictionResponse(
            demand_score=demand_score,
            demand_level=demand_level,
            confidence=round(confidence, 3),
            input_summary=input_summary,
            recommendations=recommendations
        )
        
        print(f"✅ Prediction successful: {demand_score} ({demand_level})")
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Prediction failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.post("/predict-batch")
async def predict_batch(requests: List[PredictionRequest]):
    """
    Batch prediction endpoint for multiple regions/countries
    """
    if len(requests) > 50:
        raise HTTPException(status_code=400, detail="Batch size cannot exceed 50 requests")
    
    results = []
    for i, request in enumerate(requests):
        try:
            features = {
                'cognition': request.cognition,
                'communication': request.communication,
                'hearing': request.hearing,
                'mobility': request.mobility,
                'self_care': request.self_care,
                'vision': request.vision
            }
            
            demand_score, confidence = predict_smart_glasses_demand(features)
            demand_level, _ = get_demand_interpretation(demand_score)
            
            results.append({
                "index": i,
                "demand_score": demand_score,
                "demand_level": demand_level,
                "confidence": round(confidence, 3)
            })
            
        except Exception as e:
            results.append({
                "index": i,
                "error": f"Prediction failed: {str(e)}"
            })
    
    return {"batch_results": results}

@app.get("/model-info")
async def get_model_info():
    """
    Get information about the trained model
    """
    global model, actual_feature_names
    
    model_type = "Demo Mode"
    if model is not None:
        if hasattr(model, 'n_estimators'):
            model_type = f"Random Forest Regressor (n_estimators={model.n_estimators})"
        elif hasattr(model, 'coef_'):
            model_type = "Linear Regression"
        else:
            model_type = str(type(model).__name__)
    
    return {
        "model_type": model_type,
        "features": actual_feature_names,
        "feature_count": len(actual_feature_names) if actual_feature_names else 0,
        "target": "smart_glasses_demand",
        "api_inputs": ["cognition", "communication", "hearing", "mobility", "self_care", "vision"],
        "demand_levels": {
            1: "Low Demand",
            2: "Medium Demand", 
            3: "High Demand"
        },
        "mission": "Predicting demand for AI-powered smart glasses to help the blind navigate independently"
    }

@app.get("/debug/features")
async def debug_features():
    """Debug endpoint to check feature mappings"""
    global actual_feature_names, model, scaler
    
    return {
        "model_loaded": model is not None,
        "scaler_loaded": scaler is not None,
        "expected_features": actual_feature_names,
        "feature_count": len(actual_feature_names) if actual_feature_names else 0,
        "model_type": str(type(model).__name__) if model else "No model",
        "scaler_type": str(type(scaler).__name__) if scaler else "No scaler"
    }

# Error handlers
@app.exception_handler(404)
async def not_found_handler(request: Request, exc):
    return JSONResponse(
        status_code=404,
        content={
            "error": "Endpoint not found", 
            "available_endpoints": ["/", "/predict", "/predict-batch", "/health", "/model-info", "/docs"]
        }
    )

@app.exception_handler(422)
async def validation_exception_handler(request: Request, exc):
    return JSONResponse(
        status_code=422,
        content={
            "error": "Validation Error",
            "details": "Please check that all training values are 0 (No) or 1 (Yes)",
            "message": "All fields must be integers: 0 or 1"
        }
    )

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)

print("🚀 Smart Glasses Demand Prediction API is ready!")
print("📚 Visit http://localhost:8000/docs for interactive API documentation")
print("🔍 Visit http://localhost:8000/health to check API status")
print("🔧 Visit http://localhost:8000/debug/features to check feature mappings")
print("💡 Mission: Building AI-powered smart glasses for the blind!")