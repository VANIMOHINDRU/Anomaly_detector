#load simulated app usage data, train on normal user app usage patterns, score new sessions for anomalies, log results

#features used->duration, hour_of_day

import pandas as pd
from sklearn.ensemble import IsolationForest
from datetime import datetime
import os
class AppUsageAgent:
    def __init__(self, data_path,log_path="data/app_usage_scores_log.csv"):
        self.data_path = data_path
        self.log_path = log_path
        self.model = None

    def load_data(self):
        df=pd.read_csv(self.data_path)
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        df['hour_of_day'] = df['timestamp'].dt.hour
        return df
    
    def train(self,df):
        normal_data=df[df['user'] == "user1"][['duration_minutes', 'hour_of_day']]
        self.model = IsolationForest(contamination=0.05, random_state=42)
        self.model.fit(normal_data)
        print("Model trained on normal app usage patterns.")

    def score(self, df):
        features= df[['duration_minutes', 'hour_of_day']]
        scores = self.model.decision_function(features)
        df['anomaly_score'] = -scores
        if not os.path.exists(self.log_path):
            df.to_csv(self.log_path, mode='w', header=True, index=False)
        else:
            df.to_csv(self.log_path, mode='a', header=False, index=False)

        return df[['user', 'app', 'duration_minutes', 'hour_of_day', 'anomaly_score']]
    
if __name__ == "__main__":
    agent = AppUsageAgent(data_path="data/app_usage_data.csv")
    df = agent.load_data()
    agent.train(df)
    scored_df = agent.score(df)
    print("Scored app usage data:")
    print(scored_df.head(10))
    print(f"Scores logged to {agent.log_path}")