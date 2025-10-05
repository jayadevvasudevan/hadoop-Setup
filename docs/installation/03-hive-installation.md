# Apache Hive Installation and Configuration

Apache Hive provides a SQL-like interface for querying and managing large datasets stored in Hadoop HDFS. This guide covers installing and configuring Hive on your Hadoop edge node.

## Prerequisites

Before installing Hive, ensure:
- [x] Hadoop is installed and running
- [x] Java 8 or 11 is installed
- [x] MySQL or PostgreSQL is available (for Metastore)

## Download and Install Hive

### Step 1: Download Apache Hive

```bash
# Switch to hadoop user
su - hadoop

# Navigate to downloads directory
cd /tmp

# Download Hive 3.1.3 (compatible with Hadoop 3.x)
wget https://downloads.apache.org/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz

# Verify download (optional)
wget https://downloads.apache.org/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz.sha512
sha512sum -c apache-hive-3.1.3-bin.tar.gz.sha512

# Extract Hive
tar -xzf apache-hive-3.1.3-bin.tar.gz

# Move to installation directory
sudo mv apache-hive-3.1.3-bin /opt/hive/
sudo chown -R hadoop:hadoop /opt/hive/
```

### Step 2: Configure Environment Variables

```bash
# Edit .bashrc
nano ~/.bashrc

# Add Hive environment variables
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HIVE_HOME/bin
export HIVE_CONF_DIR=$HIVE_HOME/conf
export CLASSPATH=$CLASSPATH:$HADOOP_HOME/lib/*:.
export CLASSPATH=$CLASSPATH:$HIVE_HOME/lib/*:.

# Reload environment
source ~/.bashrc

# Verify installation
hive --version
```

## Configure Metastore Database

Hive requires a database to store metadata. We'll use MySQL as an example.

### Step 3: Install and Configure MySQL

```bash
# Install MySQL (Ubuntu/Debian)
sudo apt update
sudo apt install mysql-server

# Start MySQL service
sudo systemctl start mysql
sudo systemctl enable mysql

# Secure MySQL installation
sudo mysql_secure_installation

# Log into MySQL
sudo mysql -u root -p
```

### Step 4: Create Hive Database and User

```sql
-- Create database for Hive Metastore
CREATE DATABASE hive_metastore;

-- Create Hive user
CREATE USER 'hive'@'localhost' IDENTIFIED BY 'hive_password';
CREATE USER 'hive'@'%' IDENTIFIED BY 'hive_password';

-- Grant permissions
GRANT ALL PRIVILEGES ON hive_metastore.* TO 'hive'@'localhost';
GRANT ALL PRIVILEGES ON hive_metastore.* TO 'hive'@'%';

-- Flush privileges
FLUSH PRIVILEGES;

-- Exit MySQL
EXIT;
```

### Step 5: Download MySQL JDBC Driver

```bash
# Download MySQL JDBC driver
cd /tmp
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.33.tar.gz

# Extract and copy to Hive lib
tar -xzf mysql-connector-java-8.0.33.tar.gz
cp mysql-connector-java-8.0.33/mysql-connector-java-8.0.33.jar $HIVE_HOME/lib/

# Also copy to Hadoop lib (for compatibility)
cp mysql-connector-java-8.0.33/mysql-connector-java-8.0.33.jar $HADOOP_HOME/share/hadoop/common/lib/
```

## Configure Hive

### Step 6: Create Hive Configuration Files

```bash
# Navigate to Hive configuration directory
cd $HIVE_CONF_DIR

# Copy template files
cp hive-default.xml.template hive-site.xml
cp hive-env.sh.template hive-env.sh
cp hive-exec-log4j2.properties.template hive-exec-log4j2.properties
cp hive-log4j2.properties.template hive-log4j2.properties
```

### Step 7: Configure hive-site.xml

```bash
# Edit hive-site.xml
nano hive-site.xml
```

Replace the content with:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <!-- Metastore connection -->
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://localhost:3306/hive_metastore?useSSL=false&amp;allowPublicKeyRetrieval=true</value>
        <description>JDBC connection URL for Metastore</description>
    </property>
    
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.cj.jdbc.Driver</value>
        <description>JDBC driver for Metastore</description>
    </property>
    
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>
        <description>Username for Metastore connection</description>
    </property>
    
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>hive_password</value>
        <description>Password for Metastore connection</description>
    </property>
    
    <!-- Warehouse directory -->
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>/user/hive/warehouse</value>
        <description>Location of default database for the warehouse</description>
    </property>
    
    <!-- Metastore service -->
    <property>
        <name>hive.metastore.uris</name>
        <value>thrift://localhost:9083</value>
        <description>Thrift URI for the remote metastore</description>
    </property>
    
    <property>
        <name>hive.metastore.schema.verification</name>
        <value>false</value>
        <description>Enforce metastore schema version consistency</description>
    </property>
    
    <!-- HiveServer2 -->
    <property>
        <name>hive.server2.thrift.port</name>
        <value>10000</value>
        <description>Port number of HiveServer2 Thrift interface</description>
    </property>
    
    <property>
        <name>hive.server2.thrift.bind.host</name>
        <value>0.0.0.0</value>
        <description>Bind host on which to run the HiveServer2 Thrift service</description>
    </property>
    
    <property>
        <name>hive.server2.webui.host</name>
        <value>0.0.0.0</value>
        <description>Host for HiveServer2 web UI</description>
    </property>
    
    <property>
        <name>hive.server2.webui.port</name>
        <value>10002</value>
        <description>Port for HiveServer2 web UI</description>
    </property>
    
    <!-- Authentication -->
    <property>
        <name>hive.server2.authentication</name>
        <value>NONE</value>
        <description>Authentication type for HiveServer2</description>
    </property>
    
    <!-- Execution engine -->
    <property>
        <name>hive.execution.engine</name>
        <value>tez</value>
        <description>Execution engine (mr, tez, spark)</description>
    </property>
    
    <!-- Performance optimizations -->
    <property>
        <name>hive.vectorized.execution.enabled</name>
        <value>true</value>
        <description>Enable vectorized query execution</description>
    </property>
    
    <property>
        <name>hive.cbo.enable</name>
        <value>true</value>
        <description>Enable cost-based optimizer</description>
    </property>
    
    <property>
        <name>hive.compute.query.using.stats</name>
        <value>true</value>
        <description>Use table statistics for query optimization</description>
    </property>
    
    <!-- Compression -->
    <property>
        <name>hive.exec.compress.output</name>
        <value>true</value>
        <description>Compress final output</description>
    </property>
    
    <property>
        <name>mapred.output.compression.codec</name>
        <value>org.apache.hadoop.io.compress.SnappyCodec</value>
        <description>Compression codec for output</description>
    </property>
</configuration>
```

### Step 8: Configure hive-env.sh

```bash
# Edit hive-env.sh
nano hive-env.sh

# Add the following lines:
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HIVE_CONF_DIR=/opt/hive/conf
export HIVE_AUX_JARS_PATH=/opt/hive/lib
```

## Install and Configure Tez (Optional but Recommended)

Tez provides better performance than MapReduce for Hive queries.

### Step 9: Download and Install Tez

```bash
# Download Tez
cd /tmp
wget https://downloads.apache.org/tez/0.10.2/apache-tez-0.10.2-bin.tar.gz

# Extract Tez
tar -xzf apache-tez-0.10.2-bin.tar.gz

# Move to installation directory
sudo mv apache-tez-0.10.2-bin /opt/tez/
sudo chown -R hadoop:hadoop /opt/tez/

# Add Tez to environment
echo 'export TEZ_HOME=/opt/tez' >> ~/.bashrc
echo 'export TEZ_CONF_DIR=$TEZ_HOME/conf' >> ~/.bashrc
echo 'export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:$TEZ_HOME/*:$TEZ_HOME/lib/*' >> ~/.bashrc
source ~/.bashrc
```

### Step 10: Configure Tez

```bash
# Create Tez configuration directory
mkdir -p $TEZ_CONF_DIR

# Create tez-site.xml
nano $TEZ_CONF_DIR/tez-site.xml
```

Add the following content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>tez.lib.uris</name>
        <value>${fs.defaultFS}/apps/tez/tez.tar.gz</value>
        <description>Tez libraries location in HDFS</description>
    </property>
    
    <property>
        <name>tez.use.cluster.hadoop-libs</name>
        <value>true</value>
        <description>Use Hadoop libraries from cluster</description>
    </property>
    
    <property>
        <name>tez.am.resource.memory.mb</name>
        <value>1024</value>
        <description>Memory for Tez Application Master</description>
    </property>
    
    <property>
        <name>tez.task.resource.memory.mb</name>
        <value>512</value>
        <description>Memory for Tez tasks</description>
    </property>
</configuration>
```

### Step 11: Upload Tez to HDFS

```bash
# Create Tez directory in HDFS
hdfs dfs -mkdir -p /apps/tez

# Create Tez tarball and upload
cd /opt/tez
tar -czf tez.tar.gz -C /opt/tez .
hdfs dfs -put tez.tar.gz /apps/tez/
```

## Initialize Hive

### Step 12: Initialize Schema

```bash
# Initialize Hive schema
schematool -initSchema -dbType mysql

# You should see output indicating successful initialization
```

### Step 13: Start Hive Services

```bash
# Start Metastore service (in background)
nohup hive --service metastore > $HIVE_HOME/logs/metastore.log 2>&1 &

# Wait a few seconds for Metastore to start
sleep 10

# Start HiveServer2 (in background)
nohup hive --service hiveserver2 > $HIVE_HOME/logs/hiveserver2.log 2>&1 &

# Check if services are running
jps | grep -E "(RunJar|HiveMetaStore)"
```

## Test Hive Installation

### Step 14: Test Hive CLI

```bash
# Test Hive CLI
hive

# Run some basic commands in Hive CLI:
```

```sql
-- Show databases
SHOW DATABASES;

-- Create a test database
CREATE DATABASE test_db;

-- Use the database
USE test_db;

-- Create a test table
CREATE TABLE employees (
    id INT,
    name STRING,
    department STRING,
    salary DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

-- Show tables
SHOW TABLES;

-- Describe table
DESCRIBE employees;

-- Exit Hive
EXIT;
```

### Step 15: Test with Sample Data

```bash
# Create sample data file
cat > /tmp/employees.csv << EOF
1,John Doe,Engineering,75000
2,Jane Smith,Marketing,65000
3,Bob Johnson,Engineering,80000
4,Alice Brown,Sales,55000
5,Charlie Wilson,Engineering,70000
EOF

# Copy to HDFS
hdfs dfs -put /tmp/employees.csv /user/hive/warehouse/test_db.db/employees/

# Test queries in Hive
hive -e "
USE test_db;
SELECT * FROM employees;
SELECT department, AVG(salary) as avg_salary FROM employees GROUP BY department;
"
```

### Step 16: Test Beeline (HiveServer2 Client)

```bash
# Connect using Beeline
beeline -u jdbc:hive2://localhost:10000

# Or connect with one command
beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;"
```

## Web Interface Access

Access Hive web interfaces:

- **HiveServer2 Web UI**: http://localhost:10002
- **Hive Metastore**: No web UI, but you can check logs

## Service Management

### Start Services

```bash
# Create service start script
cat > $HIVE_HOME/bin/start-hive.sh << 'EOF'
#!/bin/bash
echo "Starting Hive Metastore..."
nohup hive --service metastore > $HIVE_HOME/logs/metastore.log 2>&1 &
sleep 5

echo "Starting HiveServer2..."
nohup hive --service hiveserver2 > $HIVE_HOME/logs/hiveserver2.log 2>&1 &
sleep 5

echo "Hive services started!"
EOF

chmod +x $HIVE_HOME/bin/start-hive.sh
```

### Stop Services

```bash
# Create service stop script
cat > $HIVE_HOME/bin/stop-hive.sh << 'EOF'
#!/bin/bash
echo "Stopping Hive services..."

# Stop HiveServer2
pkill -f HiveServer2

# Stop Metastore
pkill -f HiveMetaStore

echo "Hive services stopped!"
EOF

chmod +x $HIVE_HOME/bin/stop-hive.sh
```

### Service Status

```bash
# Check running services
jps | grep -E "(RunJar|HiveMetaStore)"

# Check service logs
tail -f $HIVE_HOME/logs/metastore.log
tail -f $HIVE_HOME/logs/hiveserver2.log
```

## Performance Tuning

### Memory Configuration

```xml
<!-- Add to hive-site.xml for better performance -->
<property>
    <name>hive.tez.container.size</name>
    <value>1024</value>
    <description>Tez container size</description>
</property>

<property>
    <name>hive.tez.java.opts</name>
    <value>-Xmx800m</value>
    <description>JVM options for Tez</description>
</property>

<property>
    <name>hive.auto.convert.join</name>
    <value>true</value>
    <description>Auto convert joins to map joins</description>
</property>

<property>
    <name>hive.auto.convert.join.noconditionaltask.size</name>
    <value>268435456</value>
    <description>Size threshold for auto conversion</description>
</property>
```

## Troubleshooting

### Common Issues

1. **Metastore connection failed**:
   - Check MySQL service status
   - Verify database credentials
   - Check JDBC driver location

2. **HiveServer2 not starting**:
   - Check port 10000 availability
   - Verify Hadoop services are running
   - Check HiveServer2 logs

3. **Permission denied errors**:
   - Check HDFS permissions
   - Verify warehouse directory exists
   - Set proper ownership

### Useful Commands

```bash
# Check Hive configuration
hive --config

# Test Metastore connection
hive --service metastore --verbose

# Run Hive with debug
hive --hiveconf hive.root.logger=DEBUG,console

# Check service status
netstat -tlnp | grep -E "(9083|10000|10002)"
```

## Next Steps

After successfully installing Hive, proceed to:

1. **[Impala Installation](04-impala-installation.md)** - Real-time SQL queries
2. **[Spark Installation](05-spark-installation.md)** - Advanced analytics
3. **[Hive Tutorial](../tutorials/hive-tutorial.md)** - Learn Hive operations

Your Hive installation is now ready for data warehousing and SQL analytics on Hadoop!