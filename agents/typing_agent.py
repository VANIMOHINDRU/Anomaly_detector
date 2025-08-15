import pandas as pd
from sklearn.ensemble import IsolationForest #unsupervised anomaly detection
#keystrokes are a common biometric used to identify users based on their typing patterns.
class TypingAgent:
    def __init__(self, data_path, log_path="data/typing_scores_log.csv"):
        self.log_path = log_path
        self.data_path=data_path
        self.model=None


    def load_data(self):
        df=pd.read_csv(self.data_path)
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        
        return df
    
    def train(self,df):
        normal_data = df[df['user'] == 'user1'][['hold_time', 'flight_time']]
        self.model=IsolationForest(contamination=0.05, random_state=42)
        self.model.fit(normal_data)#Because anomalies are rare and “different,” they require fewer splits to isolate; normal points require more splits.The model now has a baseline of what “normal” looks like.


        print("Model trained on normal user data.")

    def score(self,df):
        features = df[['hold_time', 'flight_time']]
        scores = self.model.decision_function(features)# (higher = more normal, lower = more anomalous).
        df['anomaly_score'] = -scores #higher means more anomalous
        import os
        if not os.path.exists(self.log_path):
            df.to_csv(self.log_path, mode='w', header=True, index=False)
        else:
            df.to_csv(self.log_path, mode='a', header=False, index=False)

       
        print(f"Scores saved to {self.log_path}")
        return df[['user', 'hold_time', 'flight_time', 'anomaly_score']]
    
if __name__ == "__main__":
    agent= TypingAgent(data_path="data/typing_data.csv")
    data=agent.load_data()
    agent.train(data)
    scored=agent.score(data)
    print(scored.head(10))
