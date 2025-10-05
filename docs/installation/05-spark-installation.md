# Apache Spark Installation and Configuration

Apache Spark is a unified analytics engine for large-scale data processing with built-in modules for streaming, SQL, machine learning, and graph processing. This guide covers installing Spark on your Hadoop edge node.

## Prerequisites

Before installing Spark, ensure:
- [x] Hadoop is installed and running
- [x] Java 8 or 11 is installed
- [x] Scala is installed (optional but recommended)
- [x] Python 3.7+ is installed

## Download and Install Spark

### Step 1: Download Apache Spark

```bash
# Switch to hadoop user
su - hadoop

# Navigate to downloads directory
cd /tmp

# Download Spark 3.4.1 with Hadoop 3.3 support
wget https://downloads.apache.org/spark/spark-3.4.1/spark-3.4.1-bin-hadoop3.tgz

# Verify download (optional)
wget https://downloads.apache.org/spark/spark-3.4.1/spark-3.4.1-bin-hadoop3.tgz.sha512
sha512sum -c spark-3.4.1-bin-hadoop3.tgz.sha512

# Extract Spark
tar -xzf spark-3.4.1-bin-hadoop3.tgz

# Move to installation directory
sudo mv spark-3.4.1-bin-hadoop3 /opt/spark/
sudo chown -R hadoop:hadoop /opt/spark/
```

### Step 2: Configure Environment Variables

```bash
# Edit .bashrc
nano ~/.bashrc

# Add Spark environment variables
export SPARK_HOME=/opt/spark
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
export SPARK_CONF_DIR=$SPARK_HOME/conf
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

# For Jupyter integration (optional)
export PYSPARK_DRIVER_PYTHON=jupyter
export PYSPARK_DRIVER_PYTHON_OPTS='notebook'

# Reload environment
source ~/.bashrc

# Verify installation
spark-shell --version
pyspark --version
```

## Configure Spark

### Step 3: Configure Spark Defaults

```bash
# Navigate to Spark configuration directory
cd $SPARK_CONF_DIR

# Copy template files
cp spark-defaults.conf.template spark-defaults.conf
cp spark-env.sh.template spark-env.sh
cp log4j2.properties.template log4j2.properties
```

### Step 4: Configure spark-defaults.conf

```bash
# Edit spark-defaults.conf
nano spark-defaults.conf
```

Add the following configuration:

```properties
# Spark Configuration

# Application Properties
spark.app.name                    SparkApp
spark.master                      yarn
spark.submit.deployMode           client

# Driver Configuration
spark.driver.memory               2g
spark.driver.cores                2
spark.driver.maxResultSize        1g

# Executor Configuration
spark.executor.memory             2g
spark.executor.cores              2
spark.executor.instances          2
spark.dynamicAllocation.enabled   true
spark.dynamicAllocation.minExecutors    1
spark.dynamicAllocation.maxExecutors    4

# Memory Management
spark.sql.adaptive.enabled        true
spark.sql.adaptive.coalescePartitions.enabled    true
spark.serializer                  org.apache.spark.serializer.KryoSerializer

# HDFS Configuration
spark.hadoop.fs.defaultFS         hdfs://localhost:9000

# Event Log (for Spark History Server)
spark.eventLog.enabled            true
spark.eventLog.dir                hdfs://localhost:9000/spark-logs
spark.history.fs.logDirectory     hdfs://localhost:9000/spark-logs

# SQL Warehouse
spark.sql.warehouse.dir           hdfs://localhost:9000/user/hive/warehouse

# Hive Integration
spark.sql.catalogImplementation   hive
spark.sql.hive.metastore.version  3.1.3
spark.sql.hive.metastore.jars     path

# Performance Tuning
spark.sql.adaptive.skewJoin.enabled    true
spark.sql.execution.arrow.pyspark.enabled    true

# Compression
spark.io.compression.codec        snappy

# Network
spark.network.timeout             800s
spark.sql.broadcastTimeout       36000

# UI Configuration
spark.ui.enabled                  true
spark.ui.port                     4040
```

### Step 5: Configure spark-env.sh

```bash
# Edit spark-env.sh
nano spark-env.sh
```

Add the following configuration:

```bash
#!/usr/bin/env bash

# Java Configuration
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Hadoop Configuration
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export YARN_CONF_DIR=$HADOOP_CONF_DIR

# Hive Configuration
export HIVE_HOME=/opt/hive
export HIVE_CONF_DIR=$HIVE_HOME/conf

# Spark Configuration
export SPARK_HOME=/opt/spark
export SPARK_CONF_DIR=$SPARK_HOME/conf
export SPARK_LOG_DIR=$SPARK_HOME/logs

# Python Configuration
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

# Memory Configuration
export SPARK_DAEMON_MEMORY=1g
export SPARK_MASTER_MEMORY=1g
export SPARK_WORKER_MEMORY=2g
export SPARK_WORKER_CORES=2
export SPARK_WORKER_INSTANCES=1

# JVM Options
export SPARK_DAEMON_JAVA_OPTS="-Dspark.deploy.recoveryMode=FILESYSTEM -Dspark.deploy.recoveryDirectory=$SPARK_HOME/recovery"

# History Server Configuration
export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=18080 -Dspark.history.retainedApplications=3 -Dspark.history.fs.logDirectory=hdfs://localhost:9000/spark-logs"

# Classpath
export SPARK_DIST_CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath)
```

### Step 6: Configure Logging

```bash
# Edit log4j2.properties for cleaner output
nano log4j2.properties
```

Update the root logger level:

```properties
# Root logger option
rootLogger.level = WARN
rootLogger.appenderRefs = stdout
rootLogger.appenderRef.stdout.ref = console

# Console appender configuration
appender.console.type = Console
appender.console.name = console
appender.console.target = SYSTEM_ERR
appender.console.layout.type = PatternLayout
appender.console.layout.pattern = %d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n

# Settings to quiet third party logs
logger.jetty1.name = org.sparkproject.jetty
logger.jetty1.level = WARN
logger.jetty2.name = org.sparkproject.jetty.util.component.AbstractLifeCycle
logger.jetty2.level = ERROR
logger.replexprTyper.name = org.apache.spark.repl.SparkIMain$exprTyper
logger.replexprTyper.level = INFO
logger.replSparkIMain.name = org.apache.spark.repl.SparkIMain
logger.replSparkIMain.level = INFO
logger.parquet1.name = org.apache.parquet
logger.parquet1.level = ERROR
logger.parquet2.name = parquet
logger.parquet2.level = ERROR
```

## Set Up Spark with Hadoop Integration

### Step 7: Create HDFS Directories

```bash
# Create Spark log directory in HDFS
hdfs dfs -mkdir -p /spark-logs
hdfs dfs -chmod 777 /spark-logs

# Create Spark warehouse directory
hdfs dfs -mkdir -p /user/spark/warehouse
hdfs dfs -chmod 777 /user/spark/warehouse
```

### Step 8: Copy Hive Configuration

```bash
# Copy Hive configuration to Spark
cp $HIVE_CONF_DIR/hive-site.xml $SPARK_CONF_DIR/

# Copy MySQL JDBC driver to Spark
cp $HIVE_HOME/lib/mysql-connector-java-*.jar $SPARK_HOME/jars/
```

## Install Python Dependencies

### Step 9: Install PySpark Dependencies

```bash
# Install Python packages for Spark
pip3 install --user pyspark findspark py4j pandas numpy matplotlib seaborn jupyter

# Install additional data science packages
pip3 install --user scikit-learn scipy

# Verify PySpark installation
python3 -c "import pyspark; print(pyspark.__version__)"
```

## Start Spark Services

### Step 10: Start Spark History Server

```bash
# Create start script for Spark History Server
cat > $SPARK_HOME/sbin/start-spark-history.sh << 'EOF'
#!/bin/bash

source $SPARK_HOME/conf/spark-env.sh

echo "Starting Spark History Server..."
$SPARK_HOME/sbin/start-history-server.sh

echo "Spark History Server started on http://localhost:18080"
EOF

chmod +x $SPARK_HOME/sbin/start-spark-history.sh

# Start History Server
$SPARK_HOME/sbin/start-spark-history.sh
```

### Step 11: Test Spark Installation

```bash
# Test Spark Shell (Scala)
spark-shell --master yarn --deploy-mode client

# In Spark shell, run some basic commands:
```

```scala
// Create a simple RDD
val data = Array(1, 2, 3, 4, 5)
val distData = sc.parallelize(data)

// Perform transformations and actions
val squares = distData.map(x => x * x)
squares.collect()

// Read from HDFS (if you have data)
val textFile = sc.textFile("hdfs://localhost:9000/user/hadoop/test.txt")
textFile.count()

// Exit Spark shell
:quit
```

### Step 12: Test PySpark

```bash
# Test PySpark
pyspark --master yarn --deploy-mode client

# In PySpark shell:
```

```python
# Create a simple RDD
data = [1, 2, 3, 4, 5]
distData = sc.parallelize(data)

# Perform transformations and actions
squares = distData.map(lambda x: x * x)
print(squares.collect())

# Create a DataFrame
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("Test").getOrCreate()

df = spark.createDataFrame([(1, "Alice"), (2, "Bob"), (3, "Charlie")], ["id", "name"])
df.show()

# Exit PySpark
exit()
```

## Spark SQL and Hive Integration

### Step 13: Test Spark SQL with Hive

```bash
# Start Spark SQL CLI
spark-sql --master yarn --deploy-mode client

# In Spark SQL:
```

```sql
-- Show databases (should show Hive databases)
SHOW DATABASES;

-- Use test database
USE test_db;

-- Show tables
SHOW TABLES;

-- Query Hive table from Spark
SELECT * FROM employees;

-- Create a Spark DataFrame and register as temp view
CREATE OR REPLACE TEMPORARY VIEW spark_employees AS
SELECT id, name, department, salary * 1.1 as adjusted_salary
FROM employees;

-- Query the temp view
SELECT department, AVG(adjusted_salary) as avg_adjusted_salary
FROM spark_employees
GROUP BY department;

-- Exit Spark SQL
EXIT;
```

### Step 14: Advanced Spark Example

```bash
# Create a more complex example script
cat > /tmp/spark_example.py << 'EOF'
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

# Create Spark session
spark = SparkSession.builder \
    .appName("Big Data Analytics Example") \
    .enableHiveSupport() \
    .getOrCreate()

# Create sample sales data
sales_schema = StructType([
    StructField("transaction_id", IntegerType(), True),
    StructField("customer_id", IntegerType(), True),
    StructField("product_name", StringType(), True),
    StructField("category", StringType(), True),
    StructField("amount", DoubleType(), True),
    StructField("quantity", IntegerType(), True),
    StructField("transaction_date", StringType(), True)
])

sales_data = [
    (1, 101, "Laptop", "Electronics", 1200.0, 1, "2023-01-15"),
    (2, 102, "Mouse", "Electronics", 25.0, 2, "2023-01-15"),
    (3, 103, "Coffee", "Food", 5.0, 3, "2023-01-16"),
    (4, 101, "Keyboard", "Electronics", 80.0, 1, "2023-01-16"),
    (5, 104, "Book", "Education", 15.0, 2, "2023-01-17"),
    (6, 105, "Monitor", "Electronics", 300.0, 1, "2023-01-17"),
    (7, 102, "Tea", "Food", 3.0, 5, "2023-01-18"),
    (8, 106, "Tablet", "Electronics", 500.0, 1, "2023-01-18")
]

df = spark.createDataFrame(sales_data, sales_schema)

# Register as temporary view
df.createOrReplaceTempView("sales")

# Analytics queries
print("=== Sales Analytics ===")

# Total sales by category
print("\n1. Total Sales by Category:")
category_sales = spark.sql("""
    SELECT category, 
           SUM(amount) as total_amount,
           COUNT(*) as num_transactions,
           AVG(amount) as avg_amount
    FROM sales 
    GROUP BY category 
    ORDER BY total_amount DESC
""")
category_sales.show()

# Top customers by spending
print("\n2. Top Customers by Spending:")
top_customers = spark.sql("""
    SELECT customer_id,
           SUM(amount) as total_spent,
           COUNT(*) as num_purchases
    FROM sales
    GROUP BY customer_id
    ORDER BY total_spent DESC
    LIMIT 5
""")
top_customers.show()

# Daily sales trend
print("\n3. Daily Sales Trend:")
daily_sales = spark.sql("""
    SELECT transaction_date,
           SUM(amount) as daily_total,
           COUNT(*) as daily_transactions
    FROM sales
    GROUP BY transaction_date
    ORDER BY transaction_date
""")
daily_sales.show()

# Save results to HDFS (Parquet format)
print("\n4. Saving results to HDFS...")
category_sales.write.mode("overwrite").parquet("hdfs://localhost:9000/user/hadoop/spark_results/category_sales")

# Read back and verify
print("\n5. Reading back from HDFS:")
read_back = spark.read.parquet("hdfs://localhost:9000/user/hadoop/spark_results/category_sales")
read_back.show()

# Stop Spark session
spark.stop()
print("\nAnalysis complete!")
EOF

# Run the example
python3 /tmp/spark_example.py
```

## Spark Standalone Mode (Alternative)

### Step 15: Configure Spark Standalone Mode

```bash
# Create slaves file for standalone mode
echo "localhost" > $SPARK_CONF_DIR/slaves

# Start Spark standalone cluster
$SPARK_HOME/sbin/start-master.sh
$SPARK_HOME/sbin/start-slave.sh spark://localhost:7077

# Test standalone mode
spark-shell --master spark://localhost:7077

# Stop standalone cluster
$SPARK_HOME/sbin/stop-slave.sh
$SPARK_HOME/sbin/stop-master.sh
```

## Jupyter Notebook Integration

### Step 16: Set Up Jupyter with PySpark

```bash
# Install Jupyter if not already installed
pip3 install --user jupyter jupyterlab

# Create Jupyter configuration for PySpark
jupyter notebook --generate-config

# Create PySpark kernel
cat > ~/.local/share/jupyter/kernels/pyspark/kernel.json << 'EOF'
{
    "display_name": "PySpark",
    "language": "python",
    "argv": [
        "python3",
        "-m",
        "ipykernel_launcher",
        "-f",
        "{connection_file}"
    ],
    "env": {
        "SPARK_HOME": "/opt/spark",
        "PYTHONPATH": "/opt/spark/python:/opt/spark/python/lib/py4j-0.10.9.5-src.zip",
        "PYSPARK_PYTHON": "python3",
        "PYSPARK_DRIVER_PYTHON": "python3"
    }
}
EOF

mkdir -p ~/.local/share/jupyter/kernels/pyspark

# Start Jupyter with PySpark
cd ~
PYSPARK_DRIVER_PYTHON=jupyter PYSPARK_DRIVER_PYTHON_OPTS="notebook --ip=0.0.0.0 --port=8888" pyspark --master yarn
```

## Service Management Scripts

### Step 17: Create Service Management Scripts

```bash
# Create comprehensive start script
cat > $SPARK_HOME/sbin/start-spark-services.sh << 'EOF'
#!/bin/bash

echo "Starting Spark Services..."

# Start History Server
echo "Starting Spark History Server..."
$SPARK_HOME/sbin/start-history-server.sh

echo "Spark services started!"
echo "Access points:"
echo "  History Server: http://localhost:18080"
echo "  Spark UI (when running jobs): http://localhost:4040"
EOF

chmod +x $SPARK_HOME/sbin/start-spark-services.sh

# Create stop script
cat > $SPARK_HOME/sbin/stop-spark-services.sh << 'EOF'
#!/bin/bash

echo "Stopping Spark Services..."

# Stop History Server
$SPARK_HOME/sbin/stop-history-server.sh

echo "Spark services stopped!"
EOF

chmod +x $SPARK_HOME/sbin/stop-spark-services.sh
```

## Performance Monitoring

### Step 18: Create Monitoring Scripts

```bash
# Create Spark monitoring script
cat > $SPARK_HOME/bin/spark-monitor.sh << 'EOF'
#!/bin/bash

echo "=== Spark Cluster Status ==="

# Check running Spark processes
echo "Running Spark processes:"
ps aux | grep -E "(HistoryServer|SparkSubmit)" | grep -v grep

echo -e "\n=== Spark History Server ==="
if curl -s http://localhost:18080 > /dev/null; then
    echo "History Server: RUNNING (http://localhost:18080)"
else
    echo "History Server: NOT RUNNING"
fi

echo -e "\n=== YARN Applications ==="
yarn application -list -appStates RUNNING | head -10

echo -e "\n=== HDFS Space Usage ==="
hdfs dfs -df -h

echo -e "\n=== Recent Spark Logs ==="
if [ -d "$SPARK_HOME/logs" ]; then
    echo "Recent History Server logs:"
    tail -5 $SPARK_HOME/logs/spark-*-HistoryServer-*.out 2>/dev/null || echo "No History Server logs found"
fi
EOF

chmod +x $SPARK_HOME/bin/spark-monitor.sh
```

## Web Interfaces

Access Spark web interfaces:

- **Spark History Server**: http://localhost:18080
- **Spark Application UI**: http://localhost:4040 (when jobs are running)
- **YARN Resource Manager**: http://localhost:8088
- **Spark Master UI**: http://localhost:8080 (standalone mode)

## Troubleshooting

### Common Issues

1. **YARN memory issues**:
   ```bash
   # Check YARN configuration
   yarn-site.xml memory settings
   # Reduce Spark executor memory
   spark.executor.memory=1g
   ```

2. **Hive integration problems**:
   ```bash
   # Verify Hive Metastore is running
   jps | grep HiveMetaStore
   # Check hive-site.xml in Spark conf
   ```

3. **Python path issues**:
   ```bash
   # Set Python paths explicitly
   export PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-*-src.zip
   ```

### Performance Tuning

```bash
# For better performance, adjust these settings in spark-defaults.conf
spark.sql.adaptive.enabled=true
spark.sql.adaptive.coalescePartitions.enabled=true
spark.sql.adaptive.skewJoin.enabled=true
spark.serializer=org.apache.spark.serializer.KryoSerializer
```

## Next Steps

After successfully installing Spark, proceed to:

1. **[Scala Tutorial](../tutorials/scala-tutorial.md)** - Learn Scala for Spark
2. **[Spark Tutorial](../tutorials/spark-tutorial.md)** - Master Spark operations
3. **[Docker Setup](../docker/README.md)** - Containerized development

Your Spark installation is now ready for advanced Big Data analytics and machine learning!