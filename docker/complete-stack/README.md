# Complete Big Data Stack with Docker

This Docker Compose configuration provides a complete Big Data environment including Hadoop, Hive, Spark, and Jupyter Notebook.

## Components Included

- **Hadoop HDFS**: Distributed file system (NameNode + DataNode)
- **Hadoop YARN**: Resource manager and job scheduler
- **Apache Hive**: Data warehousing with MySQL metastore
- **Apache Spark**: Analytics engine with master and worker
- **Jupyter Notebook**: Interactive development environment with PySpark

## Prerequisites

- Docker Desktop with at least 8GB RAM allocated
- 20GB free disk space
- Windows PowerShell (for Windows users)

## Quick Start

### 1. Start the Stack

```powershell
# Navigate to the complete-stack directory
cd docker/complete-stack

# Start all services
docker-compose up -d

# Check status
docker-compose ps
```

### 2. Wait for Services to Initialize

Initial startup takes 2-3 minutes. Monitor the logs:

```powershell
# Watch all logs
docker-compose logs -f

# Check specific service
docker-compose logs -f namenode
docker-compose logs -f hive-metastore
```

### 3. Verify Services

```powershell
# Check Hadoop NameNode
curl http://localhost:9870

# Check YARN ResourceManager
curl http://localhost:8088

# Check Spark Master
curl http://localhost:8080

# Check Jupyter
curl http://localhost:8888
```

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Hadoop NameNode | http://localhost:9870 | None |
| YARN ResourceManager | http://localhost:8088 | None |
| Spark Master | http://localhost:8080 | None |
| Spark Worker | http://localhost:8081 | None |
| Jupyter Notebook | http://localhost:8888 | No token required |
| Hive Server2 | jdbc:hive2://localhost:10000 | None |

## Initial Setup

### 1. Create HDFS Directories

```powershell
# Access Hadoop container
docker exec -it hadoop-namenode bash

# Inside container, create directories
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -mkdir -p /tmp
hdfs dfs -mkdir -p /user/spark
hdfs dfs -chmod 777 /tmp
hdfs dfs -chmod 777 /user/hive/warehouse
```

### 2. Initialize Hive Schema

```powershell
# Initialize Hive Metastore
docker exec -it hive-metastore schematool -dbType mysql -initSchema
```

### 3. Test Hive Connection

```powershell
# Connect to Hive
docker exec -it hive-server2 beeline -u jdbc:hive2://localhost:10000

# Run test query
# In beeline:
# > SHOW DATABASES;
# > CREATE DATABASE test;
# > USE test;
# > CREATE TABLE sample (id INT, name STRING);
# > !quit
```

## Sample Data and Examples

### 1. Upload Sample Data

```powershell
# Copy sample data to shared volume
# Create sample CSV file
@"
id,name,department,salary
1,John Doe,Engineering,75000
2,Jane Smith,Marketing,65000
3,Bob Johnson,Engineering,80000
4,Alice Brown,Sales,55000
5,Charlie Wilson,Engineering,70000
"@ | Out-File -FilePath "./volumes/shared/employees.csv" -Encoding utf8

# Upload to HDFS
docker exec hadoop-namenode hdfs dfs -put /shared/employees.csv /user/
```

### 2. Hive Example

```powershell
# Create Hive table and load data
docker exec -it hive-server2 beeline -u jdbc:hive2://localhost:10000 -e "
CREATE DATABASE IF NOT EXISTS demo;
USE demo;
CREATE TABLE employees (
    id INT,
    name STRING,
    department STRING,
    salary DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

LOAD DATA INPATH '/user/employees.csv' INTO TABLE employees;
SELECT * FROM employees;
SELECT department, AVG(salary) as avg_salary FROM employees GROUP BY department;
"
```

### 3. Spark Example via Jupyter

Open http://localhost:8888 and create a new notebook with this content:

```python
from pyspark.sql import SparkSession

# Create Spark session
spark = SparkSession.builder \
    .appName("Docker Big Data Demo") \
    .master("spark://spark-master:7077") \
    .enableHiveSupport() \
    .getOrCreate()

# Read from Hive
df = spark.sql("SELECT * FROM demo.employees")
df.show()

# Perform analytics
dept_avg = spark.sql("""
    SELECT department, 
           AVG(salary) as avg_salary,
           COUNT(*) as employee_count
    FROM demo.employees 
    GROUP BY department
""")
dept_avg.show()

# Save results
dept_avg.write.mode("overwrite").parquet("/shared/department_analysis")

spark.stop()
```

## Data Management

### Persistent Storage

Data is stored in Docker volumes under `./volumes/`:

- `./volumes/namenode/` - HDFS NameNode metadata
- `./volumes/datanode/` - HDFS data blocks
- `./volumes/mysql/` - Hive Metastore database
- `./volumes/notebooks/` - Jupyter notebooks
- `./volumes/shared/` - Shared data between containers

### Backup Strategy

```powershell
# Backup data
docker-compose down
Compress-Archive -Path ./volumes -DestinationPath "bigdata-backup-$(Get-Date -Format 'yyyy-MM-dd').zip"

# Restore data
Expand-Archive -Path "bigdata-backup-*.zip" -DestinationPath "./"
docker-compose up -d
```

## Performance Tuning

### Memory Configuration

Edit the `docker-compose.yml` to adjust memory:

```yaml
# For containers with more memory
environment:
  - YARN_CONF_yarn_nodemanager_resource_memory_mb=4096
  - SPARK_WORKER_MEMORY=4G
```

### Scale Workers

```powershell
# Add more Spark workers
docker-compose up -d --scale spark-worker=3
```

## Troubleshooting

### Common Issues

1. **Services not starting**:
   ```powershell
   # Check Docker resources
   docker system df
   docker system prune
   ```

2. **Port conflicts**:
   ```powershell
   # Check what's using ports
   netstat -an | findstr "9870\|8088\|8080\|8888"
   ```

3. **Out of memory**:
   ```powershell
   # Increase Docker Desktop memory allocation
   # Restart Docker Desktop
   ```

4. **Hive connection issues**:
   ```powershell
   # Check Metastore logs
   docker-compose logs hive-metastore
   
   # Reinitialize schema
   docker exec -it hive-metastore schematool -dbType mysql -initSchema
   ```

### Health Checks

```powershell
# Check all services
docker-compose ps

# Test HDFS
docker exec hadoop-namenode hdfs dfsadmin -report

# Test Spark
docker exec spark-master /opt/bitnami/spark/bin/spark-submit --version

# Test Hive
docker exec hive-server2 beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;"
```

### Log Monitoring

```powershell
# Monitor all logs
docker-compose logs -f

# Monitor specific service
docker-compose logs -f namenode
docker-compose logs -f hive-metastore
docker-compose logs -f spark-master
```

## Development Workflow

### 1. Development Cycle

```powershell
# Start development
docker-compose up -d

# Develop in Jupyter (http://localhost:8888)
# Test with Hive CLI or beeline
# Monitor via web UIs

# Stop when done
docker-compose down
```

### 2. Code Deployment

```powershell
# Copy code to shared volume
Copy-Item "local-script.py" "./volumes/shared/"

# Execute in Spark
docker exec spark-master /opt/bitnami/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  /shared/local-script.py
```

## Best Practices

1. **Resource Management**: Monitor Docker Desktop resource usage
2. **Data Persistence**: Always use volumes for important data
3. **Network Isolation**: Services communicate via internal network
4. **Security**: Change default passwords for production use
5. **Monitoring**: Use web UIs to monitor cluster health

## Stopping the Stack

```powershell
# Stop all services
docker-compose down

# Stop and remove volumes (CAUTION: deletes all data)
docker-compose down -v

# Stop and remove everything
docker-compose down --rmi all -v
```

This Docker environment provides a complete Big Data platform for learning and development. Start with the Jupyter notebooks for interactive exploration!