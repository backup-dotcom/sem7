import pandas as pd
from sklearn.cluster import KMeans

# Sample dataset
data = {'X': [1, 2, 3, 8, 9, 10],
        'Y': [1, 2, 3, 8, 9, 10]}

df = pd.DataFrame(data)

kmeans = KMeans(n_clusters=2, random_state=42)
df['Cluster'] = kmeans.fit_predict(df[['X', 'Y']])

print("Clustered Data:\n", df)
