import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

# Read data
df = pd.read_csv('MoviesDataset/movies.csv')

# Check for null values in different columns
for col in df.columns:
    pctg_missing = (np.mean(df[col].isnull())*100)
    # print(f'{col} - {pctg_missing}%')

# Drop rows with missing values
df.dropna(inplace=True)

# Check and correct data types of different columns
#print(df.info())
df['budget'] = df['budget'].astype('int64')
df['gross'] = df['gross'].astype('int64')
df['runtime'] = df['runtime'].astype('int64')

# Fixing year mismatch
def fix_mismatch(x):
    try:
        return x[1]
    except IndexError:
        return x[0]

# Convert the released date to string
df['released'] = df['released'].astype('string')

# Extract only the year from the released column structured like this: Date, Year (Country)
df['year released'] = df['released'].str.split(',').apply(fix_mismatch)
df['year released'] = df['year released'].str.split('(').apply(lambda x: x[0])
df['year released'] = df['year released'].str[-5:]
df['year released'] = df['year released'].astype('int64')

#print(df['year released'].value_counts())

# Order by gross revenue
df.sort_values(by=['gross'], inplace=True, ascending=False)

# Check for duplicates
#print(df.duplicated().value_counts())

# Checking for correlation between budget and gross revenue
# Create a figure with two subplots
fig, axes = plt.subplots(1, 2, figsize=(12, 6))

# Plot budget vs gross using seaborn
sns.regplot(x='budget', y='gross', data=df, ax=axes[0], line_kws={'color':'red'})
axes[0].set_title('Gross Revenue vs Budget (Seaborn)')
axes[0].set_xlabel('Budget')
axes[0].set_ylabel('Gross Revenue')

# Adjust layout
plt.tight_layout()

# Checking correlation between numeric columns
correlation_matrix = df.corr(numeric_only=True)

sns.heatmap(correlation_matrix, annot=True, ax=axes[1])
axes[1].set_title('Correlation matrix for numeric features')
axes[1].set_xlabel('Movie numerical features')


# Categorical encoding of non numerical features
df_encoded = df

for col in df_encoded.columns:
    if df_encoded[col].dtype == 'object' or df_encoded[col].dtype == 'string':
        df_encoded[col] = df_encoded[col].astype('category')
        df_encoded[col] = df_encoded[col].cat.codes

# Checking correlation between all columns
correlation_matrix_encoded = df_encoded.corr()

fig2 = plt.figure()
sns.heatmap(correlation_matrix_encoded, annot=True)
plt.title('Correlation matrix for all features')
plt.xlabel('Movies all features')
plt.show()

# Finding highest correlations linear
corr_pairs = correlation_matrix_encoded.unstack()
sorted_pairs = corr_pairs.sort_values()
high_corr = sorted_pairs[(sorted_pairs) > 0.5]
#print(high_corr)

