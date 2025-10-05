# Sample Datasets for Big Data Learning

This directory contains sample datasets for practicing with Hadoop, Hive, Impala, and Spark.

## Available Datasets

### 1. Employee Data (`employees.csv`)
- **Description**: Employee information with departments and salaries
- **Size**: Small (< 1MB)
- **Use Cases**: Basic SQL operations, aggregations, joins
- **Columns**: id, name, department, salary, hire_date

### 2. Sales Transactions (`sales_data.csv`)
- **Description**: E-commerce transaction data
- **Size**: Medium (10-50MB)
- **Use Cases**: Time series analysis, customer analytics
- **Columns**: transaction_id, customer_id, product_id, quantity, price, date

### 3. Web Logs (`web_logs.txt`)
- **Description**: Apache web server access logs
- **Size**: Large (100MB+)
- **Use Cases**: Log analysis, pattern recognition
- **Format**: Common Log Format (CLF)

### 4. Product Catalog (`products.json`)
- **Description**: Product information in JSON format
- **Size**: Small (< 5MB)
- **Use Cases**: JSON processing, semi-structured data
- **Schema**: id, name, category, price, description, specifications

### 5. Customer Reviews (`reviews.csv`)
- **Description**: Product reviews and ratings
- **Size**: Medium (20-100MB)
- **Use Cases**: Sentiment analysis, text mining
- **Columns**: review_id, product_id, customer_id, rating, review_text, date

## Data Generation Scripts

### `generate_large_dataset.py`
Generates large datasets for performance testing:
```bash
python3 generate_large_dataset.py --type sales --records 1000000 --output sales_1m.csv
```

### `create_sample_data.sh`
Shell script to create all sample datasets:
```bash
./create_sample_data.sh
```

## Usage Examples

### Upload to HDFS
```bash
# Upload all datasets
hdfs dfs -mkdir -p /datasets
hdfs dfs -put *.csv /datasets/
hdfs dfs -put *.json /datasets/
hdfs dfs -put *.txt /datasets/
```

### Create Hive Tables
```sql
-- Employee table
CREATE TABLE employees (
    id INT,
    name STRING,
    department STRING,
    salary DOUBLE,
    hire_date DATE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

LOAD DATA INPATH '/datasets/employees.csv' INTO TABLE employees;
```

### Spark Analysis
```python
# Load data in Spark
df = spark.read.csv('/datasets/sales_data.csv', header=True, inferSchema=True)
df.createOrReplaceTempView('sales')

# Analyze data
monthly_sales = spark.sql("""
    SELECT MONTH(date) as month, SUM(quantity * price) as total_sales
    FROM sales
    GROUP BY MONTH(date)
    ORDER BY month
""")
monthly_sales.show()
```

## Data Characteristics

| Dataset | Rows | Columns | Size | Format | Complexity |
|---------|------|---------|------|--------|------------|
| employees.csv | 1,000 | 5 | 50KB | CSV | Simple |
| sales_data.csv | 100,000 | 6 | 5MB | CSV | Medium |
| web_logs.txt | 1,000,000 | 10 | 200MB | Text | Complex |
| products.json | 10,000 | Variable | 2MB | JSON | Medium |
| reviews.csv | 50,000 | 6 | 25MB | CSV | Medium |

## Best Practices

1. **Start Small**: Begin with smaller datasets for learning
2. **Understand Schema**: Review data structure before analysis
3. **Use Appropriate Storage**: Choose optimal file formats (Parquet for analytics)
4. **Partition Data**: Partition large datasets by date or category
5. **Compress Data**: Use compression for storage efficiency

## Data Privacy

All datasets are either:
- Synthetically generated
- Public domain
- Anonymized samples

No real personal or confidential information is included.

## Contributing

To add new datasets:
1. Ensure data is appropriate for learning purposes
2. Include metadata and description
3. Provide usage examples
4. Update this README

## Data Sources

- **Synthetic Data**: Generated using Python scripts
- **Public Datasets**: From Kaggle, UCI ML Repository
- **Open Data**: Government and research institutions
- **Sample Data**: Created for specific learning scenarios