import pandas as pd
from sklearn.linear_model import LinearRegression

# Sample dataset
data = {'Area': [1000, 1500, 2000, 2500, 3000],
        'Bedrooms': [2, 3, 3, 4, 4],
        'Price': [200000, 250000, 300000, 350000, 400000]}

df = pd.DataFrame(data)
X = df[['Area', 'Bedrooms']]
y = df['Price']

model = LinearRegression()
model.fit(X, y)

print("Coefficients:", model.coef_)
print("Intercept:", model.intercept_)
