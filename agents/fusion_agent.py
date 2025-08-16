import pandas as pd

class FusionAgent:
    def __init__(self, weights=None):
        self.weights = weights if weights is not None else {
            'typing': 0.5,
            'app': 0.3,
            'sensor': 0.2
        }

    def fuse(self, typing_df, app_df, sensor_df):
        # --- Add conditional checks for each DataFrame ---
        if not typing_df.empty:
            typing_df['timestamp'] = pd.to_datetime(typing_df['timestamp'])
        
        if not app_df.empty:
            app_df['timestamp'] = pd.to_datetime(app_df['timestamp'])
        
        if not sensor_df.empty:
            sensor_df['timestamp'] = pd.to_datetime(sensor_df['timestamp'])

        all_dfs = {'typing': typing_df, 'app': app_df, 'sensor': sensor_df}
        
        non_empty_dfs = {k: v for k, v in all_dfs.items() if not v.empty}
        if not non_empty_dfs:
            return pd.DataFrame()

        primary_key = max(non_empty_dfs, key=lambda k: len(non_empty_dfs[k]))
        merged = non_empty_dfs[primary_key].sort_values('timestamp').copy()

        for name, df in non_empty_dfs.items():
            if name != primary_key:
                merged = pd.merge_asof(
                    merged,
                    df.sort_values('timestamp'),
                    on='timestamp',
                    by='user',
                    direction='nearest',
                    suffixes=('_', f'_{name}'),
                    tolerance=pd.Timedelta('10min')
                )

        score_cols = [f'anomaly_score_{k}' for k in self.weights.keys()]
        for col in score_cols:
            if col not in merged.columns:
                merged[col] = 0.0
            else:
                merged[col] = merged[col].fillna(0.0)

        fusion_components = []
        total_weight = 0
        for modality, weight in self.weights.items():
            col_name = f'anomaly_score_{modality}'
            if col_name in merged.columns:
                fusion_components.append(merged[col_name] * weight)
                total_weight += weight

        merged['fusion_score'] = sum(fusion_components) / (total_weight if total_weight > 0 else 1)

        print("Fusion complete. Fused scores calculated.")
        return merged[['user', 'timestamp', 'fusion_score'] + score_cols]