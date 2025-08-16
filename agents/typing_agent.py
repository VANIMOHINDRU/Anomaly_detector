import pandas as pd
from sklearn.ensemble import IsolationForest

class TypingAgent:
    def __init__(self):
        self.model = None

    def load_data(self, df):
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        return df

    def train(self, df):
        normal_data = df[df['user'] == 'user1'][['hold_time', 'flight_time']]
        self.model = IsolationForest(contamination=0.05, random_state=42)
        self.model.fit(normal_data)
        print("Model trained on normal user data.")

    def score(self, df):
        features = df[['hold_time', 'flight_time']]
        scores = self.model.decision_function(features)
        df['anomaly_score'] = -scores
        return df[['user', 'timestamp', 'anomaly_score']]