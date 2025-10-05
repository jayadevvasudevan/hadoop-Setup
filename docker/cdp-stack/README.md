# CDP Docker Environment

This Docker Compose setup provides a simplified Cloudera Data Platform (CDP) environment for learning and development. While not a full CDP installation, it includes the core components with Cloudera-compatible configurations.

## Components Included

- **Cloudera Manager** (Simplified version)
- **Hadoop HDFS** with CDP configurations
- **Apache Hive** with CDP-compatible setup
- **Apache Impala** for real-time SQL
- **Apache Spark** with CDP integration
- **PostgreSQL** for metastore services
- **Zookeeper** for coordination

## Quick Start

### Prerequisites
- Docker Desktop with 16GB+ RAM allocated
- 50GB+ free disk space

### Start CDP Environment

```powershell
# Navigate to CDP docker directory
cd docker/cdp-stack

# Start all services
docker-compose up -d

# Monitor startup (takes 5-10 minutes)
docker-compose logs -f
```

### Verify Installation

```powershell
# Check service status
docker-compose ps

# Access Cloudera Manager-like interface
curl http://localhost:7180

# Test Hadoop
docker exec cdp-namenode hdfs dfs -ls /

# Test Hive
docker exec cdp-hive beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;"
```

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Cloudera Manager | http://localhost:7180 | admin/admin |
| NameNode Web UI | http://localhost:9870 | None |
| ResourceManager | http://localhost:8088 | None |
| Hive Server2 | http://localhost:10002 | None |
| Impala Daemon | http://localhost:25000 | None |
| Spark History | http://localhost:18080 | None |

## Configuration

### CDP-Style Configurations

This environment uses CDP-compatible configurations:

- **Unified Security**: Kerberos-ready (disabled for development)
- **Service Dependencies**: Proper startup order
- **Resource Management**: YARN-based resource allocation
- **Metadata Management**: Shared metastore across services

### Environment Variables

```yaml
# Core CDP Environment
CDP_VERSION: "7.1.7"
CLUSTER_NAME: "cdp-cluster"
SECURITY_ENABLED: "false"
KERBEROS_ENABLED: "false"

# Service Configuration
HADOOP_HEAP_SIZE: "2048m"
HIVE_HEAP_SIZE: "2048m"
IMPALA_MEM_LIMIT: "4GB"
SPARK_EXECUTOR_MEMORY: "2g"
```

## Sample Workloads

### 1. Data Ingestion Pipeline

```bash
# Create sample data
docker exec cdp-namenode bash -c "
echo 'id,name,department,salary,location' > /tmp/employees.csv
echo '1,John Doe,Engineering,75000,San Francisco' >> /tmp/employees.csv
echo '2,Jane Smith,Marketing,65000,New York' >> /tmp/employees.csv
echo '3,Bob Johnson,Engineering,80000,Austin' >> /tmp/employees.csv

# Upload to HDFS
hdfs dfs -mkdir -p /cdp/data/employees
hdfs dfs -put /tmp/employees.csv /cdp/data/employees/
"
```

### 2. Hive Data Warehouse

```sql
-- Connect to Hive
docker exec -it cdp-hive beeline -u jdbc:hive2://localhost:10000

-- Create database
CREATE DATABASE cdp_demo;
USE cdp_demo;

-- Create external table
CREATE TABLE employees (
    id INT,
    name STRING,
    department STRING,
    salary BIGINT,
    location STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/cdp/data/employees';

-- Query data
SELECT department, AVG(salary) as avg_salary, COUNT(*) as count
FROM employees
GROUP BY department;
```

### 3. Impala Real-time Analytics

```bash
# Connect to Impala
docker exec -it cdp-impala impala-shell

# Refresh metadata
REFRESH cdp_demo.employees;

# Fast analytical queries
SELECT location, 
       MAX(salary) as max_salary,
       MIN(salary) as min_salary,
       AVG(salary) as avg_salary
FROM cdp_demo.employees
GROUP BY location;
```

### 4. Spark Data Processing

```python
# Start PySpark in CDP environment
docker exec -it cdp-spark pyspark \
  --master yarn \
  --deploy-mode client \
  --conf spark.sql.catalogImplementation=hive

# In PySpark shell:
# Read from Hive table
df = spark.sql("SELECT * FROM cdp_demo.employees")
df.show()

# Perform analytics
salary_stats = spark.sql("""
    SELECT 
        department,
        location,
        AVG(salary) as avg_salary,
        COUNT(*) as employee_count,
        PERCENTILE_APPROX(salary, 0.5) as median_salary
    FROM cdp_demo.employees
    GROUP BY department, location
""")

salary_stats.show()

# Save results in Parquet format
salary_stats.write.mode("overwrite").parquet("/cdp/results/salary_analysis")
```

## CDP Features Simulation

### 1. Workload Management

```yaml
# YARN Queue Configuration
yarn.scheduler.capacity.root.queues: "default,analytics,etl"
yarn.scheduler.capacity.root.default.capacity: "40"
yarn.scheduler.capacity.root.analytics.capacity: "30"
yarn.scheduler.capacity.root.etl.capacity: "30"
```

### 2. Resource Pools

```bash
# Create Impala resource pools
docker exec cdp-impala bash -c "
impala-shell -q \"
CREATE RESOURCE POOL analytics_pool WITH MAX_REQUESTS=10, MAX_MEM_RESOURCES=4GB;
CREATE RESOURCE POOL etl_pool WITH MAX_REQUESTS=5, MAX_MEM_RESOURCES=8GB;
\"
"
```

### 3. Data Governance Simulation

```sql
-- Create governed tables with metadata
CREATE TABLE cdp_demo.customer_data (
    customer_id INT COMMENT 'Unique customer identifier',
    email STRING COMMENT 'Customer email - PII',
    phone STRING COMMENT 'Customer phone - PII',
    created_date DATE COMMENT 'Account creation date'
)
COMMENT 'Customer master data - contains PII'
TBLPROPERTIES (
    'data_classification'='confidential',
    'retention_period'='7_years',
    'data_owner'='data_team@company.com'
);
```

## Monitoring and Management

### Health Checks

```bash
# Service health script
cat > /tmp/cdp_health_check.sh << 'EOF'
#!/bin/bash
echo "=== CDP Cluster Health Check ==="

echo "1. HDFS Health:"
docker exec cdp-namenode hdfs dfsadmin -report | head -10

echo -e "\n2. YARN Resource Manager:"
docker exec cdp-resourcemanager yarn node -list

echo -e "\n3. Hive Metastore:"
docker exec cdp-hive bash -c "netstat -tlnp | grep 9083" || echo "Metastore not accessible"

echo -e "\n4. Impala Daemons:"
docker exec cdp-impala bash -c "netstat -tlnp | grep 21000" || echo "Impala not accessible"

echo -e "\n5. Service Status:"
docker-compose ps
EOF

chmod +x /tmp/cdp_health_check.sh
/tmp/cdp_health_check.sh
```

### Performance Monitoring

```bash
# Resource utilization
docker stats --no-stream

# Service-specific metrics
docker exec cdp-namenode bash -c "
curl -s http://localhost:9870/jmx?qry=Hadoop:service=NameNode,name=FSNamesystem | 
python3 -c 'import sys,json; data=json.load(sys.stdin); print(f\"HDFS Usage: {data[\"beans\"][0][\"PercentUsed\"]:.2f}%\")'
"
```

## CDP Management Simulation

### 1. Service Configuration Management

```bash
# Configuration deployment simulation
docker exec cdp-namenode bash -c "
# Update Hadoop configuration
echo '<?xml version=\"1.0\"?>
<configuration>
    <property>
        <name>dfs.block.size</name>
        <value>134217728</value>
        <description>Updated block size via CDP management</description>
    </property>
</configuration>' > /opt/hadoop/etc/hadoop/hdfs-site-updates.xml
"
```

### 2. Rolling Restart Simulation

```bash
# Simulate rolling restart
echo "Performing rolling restart..."
docker-compose restart cdp-datanode
sleep 30
docker-compose restart cdp-nodemanager
sleep 30
echo "Rolling restart completed"
```

### 3. Backup and Recovery

```bash
# HDFS backup simulation
docker exec cdp-namenode bash -c "
# Create backup directory
hdfs dfs -mkdir -p /cdp/backups/$(date +%Y-%m-%d)

# Backup critical data
hdfs dfs -cp /cdp/data/* /cdp/backups/$(date +%Y-%m-%d)/

# Verify backup
hdfs dfs -ls -R /cdp/backups/$(date +%Y-%m-%d)/
"
```

## Advanced Features

### 1. Data Lineage Tracking

```sql
-- Create lineage-aware transformations
CREATE TABLE cdp_demo.employee_summary AS
SELECT 
    department,
    location,
    COUNT(*) as employee_count,
    AVG(salary) as avg_salary,
    CURRENT_TIMESTAMP() as created_date
FROM cdp_demo.employees
GROUP BY department, location;
```

### 2. Workload Analytics

```python
# Workload analysis script
docker exec cdp-spark python3 << 'EOF'
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("CDP Workload Analysis") \
    .config("spark.sql.adaptive.enabled", "true") \
    .enableHiveSupport() \
    .getOrCreate()

# Analyze query patterns
query_stats = spark.sql("""
    SELECT 
        'hive' as engine,
        COUNT(*) as query_count,
        AVG(execution_time) as avg_execution_time
    FROM information_schema.query_history
    WHERE date >= current_date - interval 1 day
""")

print("Workload Analytics:")
query_stats.show()
spark.stop()
EOF
```

## Troubleshooting

### Common Issues

1. **Services not starting**:
   ```bash
   # Check resource allocation
   docker system df
   docker system prune -f
   ```

2. **Metastore connection errors**:
   ```bash
   # Verify PostgreSQL
   docker exec cdp-postgres pg_isready
   docker-compose logs cdp-postgres
   ```

3. **YARN resource issues**:
   ```bash
   # Check YARN capacity
   docker exec cdp-resourcemanager yarn top
   ```

### Log Analysis

```bash
# Centralized log viewing
docker-compose logs --tail=100 cdp-namenode
docker-compose logs --tail=100 cdp-hive
docker-compose logs --tail=100 cdp-impala
```

## Migration to Production CDP

This Docker environment helps you:

1. **Learn CDP Concepts**: Understand service interactions
2. **Test Configurations**: Validate settings before production
3. **Develop Applications**: Build and test data pipelines
4. **Plan Deployments**: Understand resource requirements

### Production Considerations

- **Licensing**: CDP requires licenses for production use
- **Hardware**: Minimum 3-node cluster recommended
- **Security**: Enable Kerberos and TLS in production
- **Monitoring**: Use Cloudera Manager for full monitoring
- **Support**: Consider Cloudera support contracts

## Next Steps

1. **Explore CDP Features**: Try different services and configurations
2. **Develop Data Pipelines**: Build ETL workflows
3. **Performance Testing**: Test with larger datasets
4. **Security Setup**: Learn about CDP security features
5. **Plan Production**: Design your production CDP cluster

This CDP simulation provides a foundation for understanding enterprise Big Data platforms while maintaining the flexibility of containerized development.