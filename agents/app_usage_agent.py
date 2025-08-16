import pandas as pd
from sklearn.ensemble import IsolationForest
from datetime import datetime

class AppUsageAgent:
    def __init__(self):
        self.model = None

    def load_data(self, df):
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        df['hour_of_day'] = df['timestamp'].dt.hour
        return df

    def train(self, df):
        normal_data = df[df['user'] == "user1"][['duration_minutes', 'hour_of_day']]
        self.model = IsolationForest(contamination=0.05, random_state=42)
        self.model.fit(normal_data)
        print("Model trained on normal app usage patterns.")

    def score(self, df):
        features = df[['duration_minutes', 'hour_of_day']]
        scores = self.model.decision_function(features)
        df['anomaly_score'] = -scores
        return df[['user', 'timestamp', 'anomaly_score']]