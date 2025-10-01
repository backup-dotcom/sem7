import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.naive_bayes import GaussianNB
from sklearn.metrics import accuracy_score

# Sample dataset
data = {'Age': [25, 30, 45, 35, 22, 40, 29],
        'Salary': [50000, 60000, 80000, 75000, 40000, 90000, 48000],
        'Purchased': [0, 1, 1, 1, 0, 1, 0]}

df = pd.DataFrame(data)
X = df[['Age', 'Salary']]
y = df['Purchased']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)

model = GaussianNB()
model.fit(X_train, y_train)
y_pred = model.predict(X_test)

print("Accuracy:", accuracy_score(y_test, y_pred))
