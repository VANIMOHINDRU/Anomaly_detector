import pandas as pd
import numpy as np
from sklearn.ensemble import IsolationForest
from datetime import datetime

class SensorAgent:
    def __init__(self,data_path, log_path="data/sensor_scores_log.csv"):
        self.data_path = data_path
        self.log_path = log_path
        self.model = None

    def load_data(self):
        df=pd.read_csv(self.data_path)
        if 'timestamp' in df.columns:
            df['timestamp'] = pd.to_datetime(df['timestamp'])
        return df

    def train(self, df):
        normal_data=df[df['user']=="user1"][['accel_x', 'accel_y', 'accel_z']]
        self.model=IsolationForest(contamination=0.05, random_state=42)
        self.model.fit(normal_data)
        print("Model trained on normal sensor usage patterns.")

    def score(self, df):
        import os
        features = df[['accel_x', 'accel_y', 'accel_z']]
        scores = self.model.decision_function(features)
        df['anomaly_score'] = -scores
        if not os.path.exists(self.log_path):
            df.to_csv(self.log_path, mode='w', header=True, index=False)
        else:
            df.to_csv(self.log_path, mode='a', header=False, index=False)

        return df[['user', 'timestamp', 'accel_x', 'accel_y', 'accel_z', 'anomaly_score']]
    
if __name__ == "__main__":
    agent=SensorAgent(data_path="data/sensor_data.csv")
    df=agent.load_data()
    agent.train(df)
    scored_df = agent.score(df)
    print("Scored sensor data:")
    print(scored_df.head(10))
    print(f"Scores logged to {agent.log_path}")