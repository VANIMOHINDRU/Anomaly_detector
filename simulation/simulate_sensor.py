import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
import os

os.makedirs('data', exist_ok=True)

def simulate_sensor_data(days=7,normal_user="user1",num_anomalies=8):
    records = []
    start_date = datetime.now() - timedelta(days=days)  # 7 days before today

    for day in range(days):
        date = start_date + timedelta(days=day)
        num_records = random.randint(20,50)  # Random number of readings per day

        for _ in range(num_records):
            hour = random.randint(0, 23)
            minute = random.randint(0, 59)
            second = random.randint(0, 59)

            timestamp = datetime(date.year, date.month, date.day, hour, minute, second)
            accel_x = round(np.random.normal(loc=0, scale=0.5), 2)
            accel_y = round(np.random.normal(loc=0, scale=0.5), 2)
            accel_z = round(np.random.normal(loc=9.81, scale=0.5), 2)  # Simulating gravity on Z-axis

            records.append({
                "user":normal_user, 
                "timestamp":timestamp, 
                "accel_x":accel_x, 
                "accel_y":accel_y, 
                "accel_z":accel_z,
                "its_anomaly":0
                })
            
        for _ in range(num_anomalies):
            timestamp= start_date+ timedelta(days=random.randint(0,days-1), hours=random.randint(0, 23), minutes=random.randint(0, 59), seconds=random.randint(0, 59))
            accel_x= round(np.random.normal(loc=5, scale=2), 2)
            accel_y= round(np.random.normal(loc=5, scale=2), 2)
            accel_z= round(np.random.normal(loc=15, scale=2),2)

            records.append({
                "user":"user2", 
                "timestamp":timestamp, 
                "accel_x":accel_x, 
                "accel_y":accel_y, 
                "accel_z":accel_z,
                "its_anomaly":1
            })
    df = pd.DataFrame(records)
    file_path = 'data/sensor_data.csv'
    df.to_csv(file_path, index=False)
    print(f"Sensor data simulated and saved to {file_path}")

    return df

if __name__ == "__main__":
    df= simulate_sensor_data()
    print(df.head())  # Display the first few records of the simulated data