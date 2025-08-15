from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict
from agents.typing_agent import TypingAgent
from agents.app_usage_agent import AppUsageAgent
from agents.sensor_agent import SensorAgent
from agents.fusion_agent import FusionAgent
import pandas as pd

app = FastAPI(title="On-Device Anomaly Detection")

# --- Pydantic models for incoming data ---
class TypingData(BaseModel):
    user: str
    hold_time: float
    flight_time: float

class AppUsageData(BaseModel):
    user: str
    app: str
    duration_minutes: float
    timestamp: str

class SensorData(BaseModel):
    user: str
    accel_x: float
    accel_y: float
    accel_z: float
    timestamp: str

class UserData(BaseModel):
    typing: List[TypingData]
    app_usage: List[AppUsageData]
    sensor: List[SensorData]

# --- Load agents once at startup ---
typing_agent = TypingAgent(data_path="data/typing_data.csv")
app_agent = AppUsageAgent(data_path="data/app_usage_data.csv")
sensor_agent = SensorAgent(data_path="data/sensor_data.csv")

# Train models on normal user data
typing_agent.train(typing_agent.load_data())
app_agent.train(app_agent.load_data())
sensor_agent.train(sensor_agent.load_data())

fusion_agent = FusionAgent()  # Uses default weights if not provided

# --- Endpoint for anomaly check ---
@app.post("/check_anomaly")
def check_anomaly(user_data: UserData):
    # Convert incoming JSON lists to DataFrames
    typing_df = pd.DataFrame([t.dict() for t in user_data.typing])
    app_df = pd.DataFrame([a.dict() for a in user_data.app_usage])
    sensor_df = pd.DataFrame([s.dict() for s in user_data.sensor])

    # Score each modality
    typing_scores = typing_agent.score(typing_df)
    app_df['timestamp'] = pd.to_datetime(app_df['timestamp'])
    app_df['hour_of_day'] = app_df['timestamp'].dt.hour
    app_scores = app_agent.score(app_df)
    sensor_scores = sensor_agent.score(sensor_df)

    # --- Ensure timestamp exists for FusionAgent ---
    if 'timestamp' not in typing_scores.columns:
        typing_scores['timestamp'] = pd.date_range(start=pd.Timestamp.now(), periods=len(typing_scores), freq='S')

    if 'timestamp' not in app_scores.columns:
        app_scores['timestamp'] = pd.date_range(start=pd.Timestamp.now(), periods=len(app_scores), freq='S')

    if 'timestamp' not in sensor_scores.columns:
        sensor_scores['timestamp'] = pd.date_range(start=pd.Timestamp.now(), periods=len(sensor_scores), freq='S')

    # Save temporarily to CSVs for FusionAgent to read
    typing_scores.to_csv("data/temp_typing_scores.csv", index=False)
    app_scores.to_csv("data/temp_app_scores.csv", index=False)
    sensor_scores.to_csv("data/temp_sensor_scores.csv", index=False)

    # Update FusionAgent paths to use temp files
    fusion_agent.typing_log = "data/temp_typing_scores.csv"
    fusion_agent.app_log = "data/temp_app_scores.csv"
    fusion_agent.sensor_log = "data/temp_sensor_scores.csv"

    # Fuse the scores
    fused_df = fusion_agent.fuse()

    # Decide if an anomaly is detected
    latest_score = fused_df['fusion_score'].iloc[-1]
    anomaly_detected = bool(latest_score > 0.5)  # Adjust threshold as needed

    return {
        "anomaly": anomaly_detected,
        "fusion_score": float(latest_score)
    }
