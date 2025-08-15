import pandas as pd

class FusionAgent:
    def __init__(self, typing_log="data/typing_scores_log.csv",
                 app_log="data/app_usage_scores_log.csv",
                 sensor_log="data/sensor_scores_log.csv",
                 fusion_log="data/fusion_scores_log.csv", weights=None):
        
        self.typing_log = typing_log
        self.app_log = app_log  
        self.sensor_log = sensor_log
        self.fusion_log = fusion_log
        self.weights = weights if weights is not None else {
            'typing': 0.5,
            'app': 0.3,
            'sensor': 0.2
        }

    def load_scores(self):
        typing_df = pd.read_csv(self.typing_log).rename(columns={'anomaly_score': 'anomaly_score_typing'})
        app_df = pd.read_csv(self.app_log).rename(columns={'anomaly_score': 'anomaly_score_app'})
        sensor_df = pd.read_csv(self.sensor_log).rename(columns={'anomaly_score': 'anomaly_score_sensor'})

        for df in [typing_df, app_df, sensor_df]:
            if 'timestamp' in df.columns:
                df['timestamp'] = pd.to_datetime(df['timestamp'])
            else:
                print("Warning: timestamp column missing in", df)
                df['timestamp'] = pd.date_range(start=pd.Timestamp.now(), periods=len(df), freq='S')
        return typing_df, app_df, sensor_df


    def fuse(self):
        typing_df, app_df, sensor_df = self.load_scores()
        score_cols={
            'typing': 'anomaly_score_typing' if 'anomaly_score_typing' in typing_df.columns else None,
            'app':'anomaly_score_app' if 'anomaly_score_app' in app_df.columns else None,
            'sensor':'anomaly_score_sensor' if 'anomaly_score_sensor' in sensor_df.columns else None,
        }
        merged= typing_df.copy() if score_cols['typing'] else pd.DataFrame({'user':[],'timestamp':[]})

        if score_cols['app']:
            merged = pd.merge_asof(
                merged.sort_values('timestamp'),
                app_df.sort_values('timestamp'),
                on='timestamp',
                by='user',
                direction='nearest',
                tolerance=pd.Timedelta('10min'),#merge by nearest timestamp within 1 minute
                suffixes=('_', '_app')
            )
        
        if score_cols['sensor']:
            merged = pd.merge_asof(
                merged.sort_values('timestamp'),
                sensor_df.sort_values('timestamp'),
                on='timestamp',
                by='user',
                direction='nearest',
                tolerance=pd.Timedelta('10min'),#merge by nearest timestamp within 1 minute
                suffixes=('_', '_sensor')
            )
        # Optional: fill numeric NaNs with 0 only for anomaly scoring
        for col in ['anomaly_score_typing', 'anomaly_score_app', 'anomaly_score_sensor']:
            if col in merged.columns:
                merged[col] = merged[col].fillna(0)

      
        print(merged.columns)


        fusion_components=[]
        total_weight=0

        for modality, col in score_cols.items():

            if col and col in merged.columns:
                weight=self.weights.get(modality,0)#modality → 'typing', 'app', 'sensor', col -> corresponding column name
                fusion_components.append(weight*merged[col].fillna(0))
                total_weight+=weight
        
        merged['fusion_score']=sum(fusion_components)/(total_weight if total_weight>0 else 1)
       

        merged.to_csv(self.fusion_log, index=False)
        print(f"Fusion scores saved to {self.fusion_log}")
        return merged[['user', 'timestamp', 'fusion_score', 'anomaly_score_typing', 'anomaly_score_app', 'anomaly_score_sensor']]
    
if __name__ == "__main__":
    agent = FusionAgent()
    fusion_df = agent.fuse()
    print(fusion_df.head(10))