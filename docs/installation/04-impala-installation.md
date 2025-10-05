# Apache Impala Installation and Configuration

Apache Impala provides lightning-fast, distributed SQL queries directly on data stored in HDFS and HBase, without requiring data movement or transformation. This guide covers installing Impala on your Hadoop edge node.

## Prerequisites

Before installing Impala, ensure:
- [x] Hadoop is installed and running
- [x] Hive is installed and configured
- [x] Java 8 or 11 is installed
- [x] Sufficient RAM (minimum 8GB recommended)

## Download and Install Impala

### Step 1: Download Impala

```bash
# Switch to hadoop user
su - hadoop

# Navigate to downloads directory
cd /tmp

# Download Impala 4.1.0 (latest stable version)
wget https://downloads.apache.org/impala/4.1.0/impala-4.1.0-bin.tar.gz

# Verify download (optional)
wget https://downloads.apache.org/impala/4.1.0/impala-4.1.0-bin.tar.gz.sha512
sha512sum -c impala-4.1.0-bin.tar.gz.sha512

# Extract Impala
tar -xzf impala-4.1.0-bin.tar.gz

# Move to installation directory
sudo mv impala-4.1.0-bin /opt/impala/
sudo chown -R hadoop:hadoop /opt/impala/
```

### Step 2: Configure Environment Variables

```bash
# Edit .bashrc
nano ~/.bashrc

# Add Impala environment variables
export IMPALA_HOME=/opt/impala
export PATH=$PATH:$IMPALA_HOME/bin
export IMPALA_CONF_DIR=$IMPALA_HOME/conf
export CLASSPATH=$CLASSPATH:$IMPALA_HOME/lib/*:.

# Reload environment
source ~/.bashrc

# Verify installation
impala-shell --version
```

## Configure Impala

### Step 3: Create Configuration Directory

```bash
# Create Impala configuration directory
mkdir -p $IMPALA_CONF_DIR

# Create log directory
mkdir -p $IMPALA_HOME/logs
```

### Step 4: Configure Impala Default Settings

```bash
# Create impala-env.sh
nano $IMPALA_CONF_DIR/impala-env.sh
```

Add the following content:

```bash
#!/bin/bash

# Java settings
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Hadoop settings
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_CLASSPATH=$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/yarn/lib/*

# Hive settings
export HIVE_HOME=/opt/hive
export HIVE_CONF_DIR=$HIVE_HOME/conf

# Impala settings
export IMPALA_HOME=/opt/impala
export IMPALA_CONF_DIR=$IMPALA_HOME/conf
export IMPALA_LOG_DIR=$IMPALA_HOME/logs

# Memory settings (adjust based on your system)
export IMPALA_SERVER_ARGS="--mem_limit=4GB"
export IMPALA_STATE_STORE_ARGS="--mem_limit=1GB"
export IMPALA_CATALOG_ARGS="--mem_limit=2GB"

# Network settings
export IMPALA_BE_PORT=22000
export IMPALA_BEESWAX_PORT=21000
export IMPALA_HS2_PORT=21050
export IMPALA_STATE_STORE_PORT=24000
export IMPALA_CATALOG_SERVICE_PORT=26000
export IMPALA_WEBSERVER_PORT=25000

# Additional JVM options
export IMPALA_SERVER_ARGS="$IMPALA_SERVER_ARGS --enable_webserver=true"
export IMPALA_SERVER_ARGS="$IMPALA_SERVER_ARGS --webserver_port=$IMPALA_WEBSERVER_PORT"
```

### Step 5: Configure Impala Core Settings

```bash
# Create core-site.xml link (Impala uses Hadoop configuration)
ln -sf $HADOOP_CONF_DIR/core-site.xml $IMPALA_CONF_DIR/core-site.xml
ln -sf $HADOOP_CONF_DIR/hdfs-site.xml $IMPALA_CONF_DIR/hdfs-site.xml

# Create hive-site.xml link (Impala uses Hive Metastore)
ln -sf $HIVE_CONF_DIR/hive-site.xml $IMPALA_CONF_DIR/hive-site.xml
```

### Step 6: Configure Impala Flags

```bash
# Create impala daemon flags
cat > $IMPALA_CONF_DIR/impalad_flags << 'EOF'
# Impala Daemon Configuration

# Memory settings
--mem_limit=4GB
--enable_webserver=true
--webserver_port=25000

# Metastore settings
--hms_event_polling_interval_s=10

# Performance settings
--use_local_tz_for_unix_timestamp_conversions=true
--default_pool_max_requests=1000

# Security settings (for development)
--authorized_proxy_user_config=*=*

# Logging
--log_dir=/opt/impala/logs
--minloglevel=1
--max_log_files=10
EOF

# Create StateStore flags
cat > $IMPALA_CONF_DIR/state_store_flags << 'EOF'
# StateStore Configuration

# Network settings
--state_store_port=24000
--webserver_port=25010

# Logging
--log_dir=/opt/impala/logs
--minloglevel=1

# Enable web interface
--enable_webserver=true
EOF

# Create Catalog Service flags
cat > $IMPALA_CONF_DIR/catalogd_flags << 'EOF'
# Catalog Service Configuration

# Memory settings
--mem_limit=2GB

# Network settings
--catalog_service_port=26000
--webserver_port=25020

# Metastore settings
--load_catalog_in_background=true

# Logging
--log_dir=/opt/impala/logs
--minloglevel=1

# Enable web interface
--enable_webserver=true
EOF
```

## Install Required Dependencies

### Step 7: Install System Dependencies

```bash
# Install required system packages
sudo apt update
sudo apt install -y build-essential python3-dev libsasl2-dev libsasl2-modules

# Install Python dependencies for Impala
pip3 install --user impyla thrift thrift_sasl
```

### Step 8: Copy Required Libraries

```bash
# Copy Hadoop and Hive JARs to Impala lib directory
cp $HADOOP_HOME/share/hadoop/common/*.jar $IMPALA_HOME/lib/ 2>/dev/null || true
cp $HADOOP_HOME/share/hadoop/common/lib/*.jar $IMPALA_HOME/lib/ 2>/dev/null || true
cp $HADOOP_HOME/share/hadoop/hdfs/*.jar $IMPALA_HOME/lib/ 2>/dev/null || true
cp $HIVE_HOME/lib/*.jar $IMPALA_HOME/lib/ 2>/dev/null || true

# Remove duplicate and conflicting JARs (if any)
rm -f $IMPALA_HOME/lib/slf4j-log4j12-*.jar 2>/dev/null || true
```

## Start Impala Services

### Step 9: Create Service Management Scripts

```bash
# Create start script
cat > $IMPALA_HOME/bin/start-impala.sh << 'EOF'
#!/bin/bash

source /opt/impala/conf/impala-env.sh

echo "Starting Impala StateStore..."
nohup $IMPALA_HOME/bin/statestored \
    --flagfile=$IMPALA_CONF_DIR/state_store_flags > \
    $IMPALA_LOG_DIR/statestored.log 2>&1 &

sleep 5

echo "Starting Impala Catalog Service..."
nohup $IMPALA_HOME/bin/catalogd \
    --flagfile=$IMPALA_CONF_DIR/catalogd_flags > \
    $IMPALA_LOG_DIR/catalogd.log 2>&1 &

sleep 5

echo "Starting Impala Daemon..."
nohup $IMPALA_HOME/bin/impalad \
    --flagfile=$IMPALA_CONF_DIR/impalad_flags > \
    $IMPALA_LOG_DIR/impalad.log 2>&1 &

sleep 10

echo "Impala services started!"
echo "Web interfaces:"
echo "  Impala Daemon:      http://localhost:25000"
echo "  StateStore:         http://localhost:25010"
echo "  Catalog Service:    http://localhost:25020"
EOF

chmod +x $IMPALA_HOME/bin/start-impala.sh

# Create stop script
cat > $IMPALA_HOME/bin/stop-impala.sh << 'EOF'
#!/bin/bash

echo "Stopping Impala services..."

# Stop Impala Daemon
pkill -f impalad

# Stop Catalog Service
pkill -f catalogd

# Stop StateStore
pkill -f statestored

echo "Impala services stopped!"
EOF

chmod +x $IMPALA_HOME/bin/stop-impala.sh
```

### Step 10: Start Impala Services

```bash
# Make sure Hadoop and Hive are running
start-dfs.sh
start-yarn.sh
$HIVE_HOME/bin/start-hive.sh

# Start Impala services
$IMPALA_HOME/bin/start-impala.sh

# Verify services are running
jps | grep -E "(StateStore|CatalogServer|ImpalaDaemon)"
```

## Test Impala Installation

### Step 11: Test Impala Shell

```bash
# Connect to Impala using impala-shell
impala-shell

# Run basic commands in Impala shell:
```

```sql
-- Show databases
SHOW DATABASES;

-- Use the test database created in Hive
USE test_db;

-- Show tables (should show tables created in Hive)
SHOW TABLES;

-- Query data
SELECT * FROM employees;

-- Run aggregation query
SELECT department, AVG(salary) as avg_salary 
FROM employees 
GROUP BY department;

-- Show table statistics
SHOW TABLE STATS employees;

-- Exit Impala shell
EXIT;
```

### Step 12: Test with Performance Query

```bash
# Create a larger test dataset
impala-shell -q "
USE test_db;

-- Create a partitioned table
CREATE TABLE sales (
    id INT,
    product STRING,
    amount DOUBLE,
    sale_date STRING
)
PARTITIONED BY (year INT, month INT)
STORED AS PARQUET;

-- Insert sample data
INSERT INTO sales PARTITION (year=2023, month=1) VALUES
(1, 'Laptop', 1200.00, '2023-01-15'),
(2, 'Mouse', 25.00, '2023-01-20'),
(3, 'Keyboard', 80.00, '2023-01-25');

INSERT INTO sales PARTITION (year=2023, month=2) VALUES
(4, 'Monitor', 300.00, '2023-02-10'),
(5, 'Tablet', 500.00, '2023-02-15'),
(6, 'Phone', 800.00, '2023-02-20');

-- Query with aggregation
SELECT year, month, COUNT(*) as num_sales, SUM(amount) as total_amount
FROM sales
GROUP BY year, month
ORDER BY year, month;
"
```

### Step 13: Test JDBC Connection

```bash
# Test connection using beeline (from Hive)
beeline -u "jdbc:hive2://localhost:21050/;auth=noSasl" -e "SHOW DATABASES;"
```

## Web Interface Access

Access Impala web interfaces:

- **Impala Daemon Web UI**: http://localhost:25000
- **StateStore Web UI**: http://localhost:25010  
- **Catalog Service Web UI**: http://localhost:25020

## Performance Optimization

### Step 14: Configure Impala for Better Performance

```bash
# Create optimized impala daemon flags
cat > $IMPALA_CONF_DIR/impalad_flags_optimized << 'EOF'
# Optimized Impala Daemon Configuration

# Memory settings (adjust based on available RAM)
--mem_limit=6GB
--default_pool_max_mem_resources=4GB

# Performance settings
--num_scanner_threads=16
--scan_range_length=8388608
--max_scan_range_length=33554432

# Caching
--use_local_tz_for_unix_timestamp_conversions=true
--enable_partitioned_hash_join=true
--enable_partitioned_aggregation=true

# Admission control
--default_pool_max_requests=200
--queue_wait_timeout_ms=60000

# Networking
--rpc_cnxn_retry_interval_ms=2000

# Web interface
--enable_webserver=true
--webserver_port=25000

# Statistics
--invalidate_tables_timeout_s=600

# Logging
--log_dir=/opt/impala/logs
--minloglevel=1
--max_log_files=10
EOF
```

### Step 15: Optimize Parquet Files

```sql
-- In impala-shell, optimize table storage
COMPUTE STATS employees;
COMPUTE STATS sales;

-- Refresh metadata after changes
REFRESH employees;
REFRESH sales;

-- Show file format and compression
SHOW TABLE STATS sales;
SHOW COLUMN STATS sales;
```

## Service Management

### Monitor Services

```bash
# Check service status
ps aux | grep -E "(impalad|catalogd|statestored)"

# Check logs
tail -f $IMPALA_LOG_DIR/impalad.log
tail -f $IMPALA_LOG_DIR/catalogd.log
tail -f $IMPALA_LOG_DIR/statestored.log

# Check network ports
netstat -tlnp | grep -E "(21000|21050|22000|24000|25000|25010|25020|26000)"
```

### Performance Monitoring

```bash
# Create monitoring script
cat > $IMPALA_HOME/bin/impala-status.sh << 'EOF'
#!/bin/bash

echo "=== Impala Service Status ==="
echo "Services running:"
ps aux | grep -E "(impalad|catalogd|statestored)" | grep -v grep

echo -e "\n=== Port Status ==="
netstat -tlnp | grep -E "(21000|21050|22000|24000|25000|25010|25020|26000)"

echo -e "\n=== Memory Usage ==="
ps aux | grep -E "(impalad|catalogd|statestored)" | grep -v grep | awk '{print $11, $4"%"}'

echo -e "\n=== Recent Log Entries ==="
echo "Impala Daemon:"
tail -3 $IMPALA_LOG_DIR/impalad.log 2>/dev/null || echo "No impalad log found"

echo "Catalog Service:"
tail -3 $IMPALA_LOG_DIR/catalogd.log 2>/dev/null || echo "No catalogd log found"

echo "StateStore:"
tail -3 $IMPALA_LOG_DIR/statestored.log 2>/dev/null || echo "No statestored log found"
EOF

chmod +x $IMPALA_HOME/bin/impala-status.sh
```

## Integration with Other Tools

### Step 16: Python Integration

```python
# Test Python connection
cat > /tmp/test_impala.py << 'EOF'
from impala.dbapi import connect

# Connect to Impala
conn = connect(host='localhost', port=21050, database='test_db')
cursor = conn.cursor()

# Execute query
cursor.execute('SELECT * FROM employees LIMIT 5')

# Fetch results
results = cursor.fetchall()
for row in results:
    print(row)

# Close connection
cursor.close()
conn.close()
EOF

python3 /tmp/test_impala.py
```

### Step 17: ODBC Configuration (Optional)

```bash
# Install ODBC driver (if needed)
sudo apt install unixodbc unixodbc-dev

# Configure ODBC DSN
sudo tee /etc/odbc.ini << 'EOF'
[Impala DSN]
Description=Impala ODBC Driver
Driver=Cloudera Impala ODBC Driver
HOST=localhost
PORT=21050
DATABASE=default
EOF
```

## Troubleshooting

### Common Issues

1. **Services fail to start**:
   - Check Java installation and JAVA_HOME
   - Verify Hadoop/Hive services are running
   - Check available memory
   - Review service logs

2. **Cannot connect to Impala**:
   - Verify services are running on correct ports
   - Check firewall settings
   - Test with telnet: `telnet localhost 21050`

3. **Metadata not synchronized**:
   ```sql
   -- Refresh metadata in impala-shell
   INVALIDATE METADATA;
   REFRESH database_name.table_name;
   ```

4. **Memory errors**:
   - Reduce memory limits in configuration
   - Close other applications
   - Consider increasing system RAM

### Performance Issues

```sql
-- In impala-shell, analyze query performance
EXPLAIN SELECT * FROM large_table WHERE condition;
PROFILE; -- Run after a query to see execution details
```

### Useful Commands

```bash
# Check Impala version
impala-shell --version

# Connect with specific options
impala-shell -i localhost:21000 -d test_db

# Run query from command line
impala-shell -q "SELECT COUNT(*) FROM test_db.employees;"

# Check cluster health
impala-shell -q "SHOW SERVERS;"
```

## Next Steps

After successfully installing Impala, proceed to:

1. **[Spark Installation](05-spark-installation.md)** - Advanced analytics engine
2. **[Impala Tutorial](../tutorials/impala-tutorial.md)** - Learn Impala operations
3. **[Performance Tuning](../tutorials/performance-tuning.md)** - Optimize queries

Your Impala installation is now ready for real-time SQL analytics on Big Data!