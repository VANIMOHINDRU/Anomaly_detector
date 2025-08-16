from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict, Any
import pandas as pd
import os

from agents.typing_agent import TypingAgent
from agents.app_usage_agent import AppUsageAgent
from agents.sensor_agent import SensorAgent
from agents.fusion_agent import FusionAgent

app = FastAPI(title="On-Device Anomaly Detection")

# --- Pydantic models for incoming data ---
class TypingData(BaseModel):
    user: str
    hold_time: float
    flight_time: float
    timestamp: str

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
    gyro_x: float
    gyro_y: float
    gyro_z: float
    timestamp: str

class UserData(BaseModel):
    typing: List[TypingData]
    app_usage: List[AppUsageData]
    sensor: List[SensorData]

# --- Load agents and their training data once at startup ---
training_typing_df = pd.read_csv("data/typing_data.csv")
training_app_df = pd.read_csv("data/app_usage_data.csv")
training_sensor_df = pd.read_csv("data/sensor_data.csv")

typing_agent = TypingAgent()
app_agent = AppUsageAgent()
sensor_agent = SensorAgent()
fusion_agent = FusionAgent()

typing_agent.train(typing_agent.load_data(training_typing_df))
app_agent.train(app_agent.load_data(training_app_df))
sensor_agent.train(sensor_agent.load_data(training_sensor_df))

# --- Endpoint for anomaly check ---
@app.post("/check_anomaly")
def check_anomaly(user_data: UserData):
    # Convert incoming lists of Pydantic models to DataFrames
    typing_df = pd.DataFrame([t.dict() for t in user_data.typing])
    app_df = pd.DataFrame([a.dict() for a in user_data.app_usage])
    sensor_df = pd.DataFrame([s.dict() for s in user_data.sensor])

    print("\n--- Received Dataframes ---")
    print("Typing Data:\n", typing_df)
    print("App Usage Data:\n", app_df)
    print("Sensor Data:\n", sensor_df)
    print("---------------------------\n")

    # Score each modality conditionally based on whether data exists
    typing_scores = pd.DataFrame()
    if not typing_df.empty:
        typing_df['timestamp'] = pd.to_datetime(typing_df['timestamp'])
        typing_scores = typing_agent.score(typing_df)

    app_scores = pd.DataFrame()
    if not app_df.empty:
        app_df['timestamp'] = pd.to_datetime(app_df['timestamp'])
        app_df['hour_of_day'] = app_df['timestamp'].dt.hour
        app_scores = app_agent.score(app_df)

    sensor_scores = pd.DataFrame()
    if not sensor_df.empty:
        sensor_df['timestamp'] = pd.to_datetime(sensor_df['timestamp'])
        sensor_scores = sensor_agent.score(sensor_df)

    # Fuse the scores
    fused_df = fusion_agent.fuse(typing_scores, app_scores, sensor_scores)

    if fused_df.empty:
        return {
            "anomaly": False,
            "fusion_score": 0.0
        }

    latest_score = fused_df['fusion_score'].iloc[-1]
    anomaly_detected = bool(latest_score > 0.5)

    return {
        "anomaly": anomaly_detected,
        "fusion_score": float(latest_score)
    }