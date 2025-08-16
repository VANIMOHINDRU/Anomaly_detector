import pandas as pd
from sklearn.ensemble import IsolationForest

class SensorAgent:
    def __init__(self):
        self.model = None

    def load_data(self, df):
        if 'timestamp' in df.columns:
            df['timestamp'] = pd.to_datetime(df['timestamp'])
        return df

    def train(self, df):
        normal_data = df[df['user'] == "user1"][['accel_x', 'accel_y', 'accel_z']]
        self.model = IsolationForest(contamination=0.05, random_state=42)
        self.model.fit(normal_data)
        print("Model trained on normal sensor usage patterns.")

    def score(self, df):
        features = df[['accel_x', 'accel_y', 'accel_z']]
        scores = self.model.decision_function(features)
        df['anomaly_score'] = -scores
        return df[['user', 'timestamp', 'anomaly_score']]