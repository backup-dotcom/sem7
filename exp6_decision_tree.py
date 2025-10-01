import pandas as pd
from sklearn.tree import DecisionTreeClassifier, export_text

# Sample dataset
data = {'Age': [25, 30, 45, 35, 22, 40, 29],
        'Salary': [50000, 60000, 80000, 75000, 40000, 90000, 48000],
        'Purchased': [0, 1, 1, 1, 0, 1, 0]}

df = pd.DataFrame(data)
X = df[['Age', 'Salary']]
y = df['Purchased']

model = DecisionTreeClassifier(criterion = 'entropy')
model.fit(X, y)

tree_rules = export_text(model, feature_names=['Age', 'Salary'])
print(tree_rules)
