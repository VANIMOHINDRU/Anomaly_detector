import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
import os

os.makedirs('data', exist_ok=True)
def simulate_app_usage(days=7,normal_apps=None,num_anomalies=5):
    if normal_apps is None:
        normal_apps=["WhatsApp", "Instagram","YouTube","Chrome","Gmail","Spotify"]

    records=[]
    start_date=datetime.now() - timedelta(days=days)#->7 days before today

    for day in range(days):
        date=start_date + timedelta(days=day)

        num_sessions = random.randint(5, 15)
        for _ in range(num_sessions):
            app = random.choice(normal_apps)
            hour = random.randint(7,23)
            minute = random.randint(0, 59)
            duration = round(np.random.normal(loc=5, scale=2), 2)  # average session duration of mean 5 minutes with some variance

            timestamp = datetime(date.year, date.month, date.day, hour, minute)

            records.append({
                "user": "user1",
                "app": app,
                "timestamp": timestamp,
                "duration_minutes": duration,
                "its_anomaly": 0
            })

        for _ in range(num_anomalies):
            user="user2"
            app=random.choice(normal_apps)
            timestamp = datetime(
                date.year, date.month, date.day,
                hour=random.randint(0, 5), 
                minute=random.randint(0, 59),
                second=random.randint(0, 59)
                )

            duration = round(np.random.normal(loc=15,scale=5), 2)  # long session duration
            records.append({
                "user": user,
                "app": app,
                "timestamp": timestamp,
                "duration_minutes": duration,
                "its_anomaly": 1
            })

    

    df=pd.DataFrame(records)
    file_path = 'data/app_usage_data.csv'
    df.to_csv(file_path, index=False)
    return df


if __name__ == "__main__":
    df=simulate_app_usage(days=7)
    print(df.head(10))  # Display the first few records of the simulated data