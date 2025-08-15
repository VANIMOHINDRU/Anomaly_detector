import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import random
import os

os.makedirs('data', exist_ok=True)

def simulate_typing_data(n_samples_per_day=20, days=7, num_anomalies=5):
    records = []
    start_date = datetime.now() - timedelta(days=days)

    for day in range(days):
        date = start_date + timedelta(days=day)

        # Normal user typing sessions
        for _ in range(n_samples_per_day):
            hold_time = round(np.random.normal(0.2, 0.05), 3)
            flight_time = round(np.random.normal(0.1, 0.03), 3)
            timestamp = datetime(
                date.year, date.month, date.day,
                hour=random.randint(7, 23),
                minute=random.randint(0, 59),
                second=random.randint(0, 59)
            )
            records.append({
                "user": "user1",
                "timestamp": timestamp,
                "hold_time": hold_time,
                "flight_time": flight_time,
                "its_anomaly": 0
            })

        # Anomalous typing sessions
        for _ in range(num_anomalies):
            hold_time = round(np.random.normal(0.5, 0.1), 3)
            flight_time = round(np.random.normal(0.3, 0.1), 3)
            timestamp = datetime(
                date.year, date.month, date.day,
                hour=random.randint(0, 5),
                minute=random.randint(0, 59),
                second=random.randint(0, 59)
            )
            records.append({
                "user": "anomaly",
                "timestamp": timestamp,
                "hold_time": hold_time,
                "flight_time": flight_time,
                "its_anomaly": 1
            })

    df = pd.DataFrame(records)
    file_path = "data/typing_data.csv"
    df.to_csv(file_path, index=False)
    print(f"Typing data simulated and saved to {file_path}")
    return df


if __name__ == "__main__":
    df = simulate_typing_data()
    print(df.head(10))
