# Hadoop Installation and Configuration

This guide walks you through installing and configuring Apache Hadoop on your edge node. This setup creates a single-node Hadoop cluster suitable for development and learning.

## Download and Install Hadoop

### Step 1: Download Hadoop

```bash
# Switch to hadoop user
su - hadoop

# Navigate to downloads directory
cd /tmp

# Download Hadoop 3.3.4 (latest stable version)
wget https://downloads.apache.org/hadoop/common/hadoop-3.3.4/hadoop-3.3.4.tar.gz

# Verify download (optional)
wget https://downloads.apache.org/hadoop/common/hadoop-3.3.4/hadoop-3.3.4.tar.gz.sha512
sha512sum -c hadoop-3.3.4.tar.gz.sha512

# Extract Hadoop
tar -xzf hadoop-3.3.4.tar.gz

# Move to installation directory
sudo mv hadoop-3.3.4 /opt/hadoop/
sudo chown -R hadoop:hadoop /opt/hadoop/
```

### Step 2: Configure Environment Variables

Add Hadoop environment variables to your profile:

```bash
# Edit .bashrc
nano ~/.bashrc

# Add the following lines:
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin

# Reload environment
source ~/.bashrc

# Verify installation
hadoop version
```

## Configure Hadoop

### Step 3: Configure core-site.xml

```bash
# Navigate to Hadoop configuration directory
cd $HADOOP_CONF_DIR

# Edit core-site.xml
nano core-site.xml
```

Add the following configuration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
        <description>The default file system URI</description>
    </property>
    
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/data/hadoop/tmp</value>
        <description>Base for other temporary directories</description>
    </property>
    
    <property>
        <name>io.file.buffer.size</name>
        <value>131072</value>
        <description>Buffer size for reads/writes</description>
    </property>
</configuration>
```

### Step 4: Configure hdfs-site.xml

```bash
nano hdfs-site.xml
```

Add the following configuration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
        <description>Default block replication</description>
    </property>
    
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/data/hadoop/hdfs/namenode</value>
        <description>NameNode directory for namespace and transaction logs</description>
    </property>
    
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/data/hadoop/hdfs/datanode</value>
        <description>DataNode directory</description>
    </property>
    
    <property>
        <name>dfs.blocksize</name>
        <value>268435456</value>
        <description>HDFS block size (256MB)</description>
    </property>
    
    <property>
        <name>dfs.namenode.http-address</name>
        <value>0.0.0.0:9870</value>
        <description>NameNode web interface</description>
    </property>
</configuration>
```

### Step 5: Configure mapred-site.xml

```bash
nano mapred-site.xml
```

Add the following configuration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
        <description>MapReduce framework</description>
    </property>
    
    <property>
        <name>mapreduce.application.classpath</name>
        <value>$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
    
    <property>
        <name>mapreduce.job.maps</name>
        <value>2</value>
        <description>Default number of map tasks</description>
    </property>
    
    <property>
        <name>mapreduce.job.reduces</name>
        <value>1</value>
        <description>Default number of reduce tasks</description>
    </property>
</configuration>
```

### Step 6: Configure yarn-site.xml

```bash
nano yarn-site.xml
```

Add the following configuration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
        <description>Auxiliary services for NodeManager</description>
    </property>
    
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
    </property>
    
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>localhost</value>
        <description>ResourceManager hostname</description>
    </property>
    
    <property>
        <name>yarn.resourcemanager.address</name>
        <value>localhost:8032</value>
        <description>ResourceManager address</description>
    </property>
    
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>0.0.0.0:8088</value>
        <description>ResourceManager web interface</description>
    </property>
    
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>4096</value>
        <description>Physical memory for containers</description>
    </property>
    
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>4096</value>
        <description>Maximum memory allocation</description>
    </property>
    
    <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
        <description>Disable virtual memory checks</description>
    </property>
</configuration>
```

### Step 7: Configure Hadoop Environment

```bash
# Edit hadoop-env.sh
nano hadoop-env.sh

# Find and update the JAVA_HOME line:
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Add additional JVM options
export HADOOP_OPTS="-Djava.net.preferIPv4Stack=true"
export HADOOP_NAMENODE_OPTS="-Dhadoop.security.logger=INFO,RFAS -Dhdfs.audit.logger=INFO,NullAppender"
export HADOOP_DATANODE_OPTS="-Dhadoop.security.logger=ERROR,RFAS"
```

## Initialize and Start Hadoop

### Step 8: Create Required Directories

```bash
# Create data directories
sudo mkdir -p /data/hadoop/tmp
sudo mkdir -p /data/hadoop/hdfs/namenode
sudo mkdir -p /data/hadoop/hdfs/datanode
sudo mkdir -p /data/hadoop/logs

# Set permissions
sudo chown -R hadoop:hadoop /data/hadoop/
chmod 755 /data/hadoop/hdfs/namenode
chmod 755 /data/hadoop/hdfs/datanode
```

### Step 9: Format HDFS

**Important**: Only run this command once when setting up for the first time!

```bash
# Format the namenode
hdfs namenode -format -force

# You should see output indicating successful formatting
```

### Step 10: Start Hadoop Services

```bash
# Start HDFS services
start-dfs.sh

# Start YARN services
start-yarn.sh

# Verify services are running
jps

# You should see:
# - NameNode
# - DataNode
# - ResourceManager
# - NodeManager
# - SecondaryNameNode
```

### Step 11: Create HDFS Directories

```bash
# Create user directory in HDFS
hdfs dfs -mkdir /user
hdfs dfs -mkdir /user/hadoop
hdfs dfs -chown hadoop:hadoop /user/hadoop

# Create common directories
hdfs dfs -mkdir /tmp
hdfs dfs -chmod 777 /tmp

hdfs dfs -mkdir /user/hive
hdfs dfs -mkdir /user/hive/warehouse
hdfs dfs -chmod 777 /user/hive/warehouse
```

## Verification and Testing

### Step 12: Test Hadoop Installation

```bash
# Check HDFS status
hdfs dfsadmin -report

# Test HDFS operations
echo "Hello Hadoop!" > test.txt
hdfs dfs -put test.txt /user/hadoop/
hdfs dfs -ls /user/hadoop/
hdfs dfs -cat /user/hadoop/test.txt
hdfs dfs -rm /user/hadoop/test.txt

# Run a MapReduce example
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.4.jar pi 2 5
```

### Step 13: Access Web Interfaces

Open your web browser and access:

- **NameNode Web UI**: http://localhost:9870
- **ResourceManager Web UI**: http://localhost:8088
- **Node Manager Web UI**: http://localhost:8042

## Service Management

### Start Services

```bash
# Start all services
start-dfs.sh
start-yarn.sh

# Or start individually
hadoop-daemon.sh start namenode
hadoop-daemon.sh start datanode
yarn-daemon.sh start resourcemanager
yarn-daemon.sh start nodemanager
```

### Stop Services

```bash
# Stop all services
stop-yarn.sh
stop-dfs.sh

# Or stop individually
yarn-daemon.sh stop nodemanager
yarn-daemon.sh stop resourcemanager
hadoop-daemon.sh stop datanode
hadoop-daemon.sh stop namenode
```

### Check Service Status

```bash
# List Java processes
jps

# Check specific service logs
tail -f $HADOOP_HOME/logs/hadoop-hadoop-namenode-*.log
tail -f $HADOOP_HOME/logs/yarn-hadoop-resourcemanager-*.log
```

## Configuration Optimization

### Memory Settings (for 8GB RAM system)

Adjust these values based on your system:

```xml
<!-- In yarn-site.xml -->
<property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>6144</value> <!-- 6GB for containers -->
</property>

<property>
    <name>yarn.scheduler.maximum-allocation-mb</name>
    <value>6144</value>
</property>

<property>
    <name>yarn.app.mapreduce.am.resource.mb</name>
    <value>1024</value>
</property>
```

### JVM Heap Settings

```bash
# In hadoop-env.sh
export HADOOP_NAMENODE_OPTS="-Xmx1024m"
export HADOOP_DATANODE_OPTS="-Xmx512m"
export YARN_RESOURCEMANAGER_OPTS="-Xmx1024m"
export YARN_NODEMANAGER_OPTS="-Xmx512m"
```

## Troubleshooting

### Common Issues

1. **NameNode fails to start**:
   - Check if port 9000 is available
   - Verify JAVA_HOME is set correctly
   - Check namenode logs

2. **DataNode fails to connect**:
   - Ensure SSH is working: `ssh localhost`
   - Check firewall settings
   - Verify datanode directory permissions

3. **YARN services not starting**:
   - Check memory settings
   - Verify ResourceManager logs
   - Ensure all environment variables are set

### Log Locations

```bash
# Hadoop logs
$HADOOP_HOME/logs/

# HDFS logs
tail -f $HADOOP_HOME/logs/hadoop-*-namenode-*.log
tail -f $HADOOP_HOME/logs/hadoop-*-datanode-*.log

# YARN logs
tail -f $HADOOP_HOME/logs/yarn-*-resourcemanager-*.log
tail -f $HADOOP_HOME/logs/yarn-*-nodemanager-*.log
```

## Next Steps

After successfully installing Hadoop, proceed to:

1. **[Hive Installation](03-hive-installation.md)** - Set up data warehousing
2. **[Impala Installation](04-impala-installation.md)** - Configure real-time queries
3. **[Spark Installation](05-spark-installation.md)** - Install analytics engine

Your Hadoop edge node is now ready for Big Data processing!