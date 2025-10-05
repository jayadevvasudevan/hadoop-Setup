# Cloudera Data Platform (CDP) Installation Guide

Cloudera Data Platform (CDP) is an enterprise data platform that combines the best of Cloudera Data Hub and Hortonworks Data Platform. This guide covers installing CDP Private Cloud Base (formerly CDH) on your edge node.

## CDP Overview

### What is CDP?
- **Unified Platform**: Combines analytics, machine learning, and data management
- **Enterprise Security**: Built-in security, governance, and compliance
- **Hybrid Cloud**: Consistent experience across on-premises and cloud
- **Integrated Components**: Hadoop, Spark, Hive, Impala, Kafka, and more

### CDP Editions
1. **CDP Private Cloud Base** (Free) - Core platform components
2. **CDP Private Cloud Plus** (Licensed) - Advanced features and support
3. **CDP Public Cloud** - Managed cloud services

## Prerequisites

### System Requirements
- **OS**: RHEL/CentOS 7.x or 8.x, Ubuntu 18.04/20.04
- **Memory**: Minimum 32GB RAM (64GB+ recommended)
- **Storage**: 1TB+ available space
- **CPU**: 8+ cores
- **Network**: High-speed network connectivity

### Required Software
- **Java**: OpenJDK 8 or 11
- **Python**: 3.6+
- **Database**: PostgreSQL, MySQL, or Oracle (for services)
- **NTP**: Time synchronization
- **DNS**: Proper hostname resolution

## Installation Methods

### Method 1: Cloudera Manager (Recommended)

#### Step 1: Download Cloudera Manager

```bash
# Add Cloudera repository
sudo wget https://archive.cloudera.com/cm7/7.7.1/redhat7/yum/cloudera-manager.repo \
  -P /etc/yum.repos.d/

# Import GPG key
sudo rpm --import https://archive.cloudera.com/cm7/7.7.1/redhat7/yum/RPM-GPG-KEY-cloudera

# Install Cloudera Manager Server
sudo yum install cloudera-manager-server -y
```

#### Step 2: Install and Configure Database

```bash
# Install PostgreSQL
sudo yum install postgresql-server -y

# Initialize database
sudo postgresql-setup initdb

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database for Cloudera Manager
sudo -u postgres psql << EOF
CREATE DATABASE scm;
CREATE USER scm WITH PASSWORD 'scm_password';
GRANT ALL PRIVILEGES ON DATABASE scm TO scm;
\q
EOF
```

#### Step 3: Configure Cloudera Manager

```bash
# Prepare database schema
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh postgresql scm scm scm_password

# Start Cloudera Manager
sudo systemctl start cloudera-scm-server
sudo systemctl enable cloudera-scm-server

# Check status
sudo systemctl status cloudera-scm-server
```

#### Step 4: Access Cloudera Manager Web UI

1. Open browser: `http://your-server:7180`
2. Login: `admin/admin`
3. Follow installation wizard

### Method 2: Manual Installation

#### Step 1: Download CDP Parcel

```bash
# Create parcel directory
sudo mkdir -p /opt/cloudera/parcel-repo

# Download CDP parcel (adjust version as needed)
CDP_VERSION="7.1.7.1000"
wget https://archive.cloudera.com/cdh7/${CDP_VERSION}/parcels/CDH-${CDP_VERSION}-el7.parcel \
  -P /opt/cloudera/parcel-repo/

# Download checksum
wget https://archive.cloudera.com/cdh7/${CDP_VERSION}/parcels/CDH-${CDP_VERSION}-el7.parcel.sha \
  -P /opt/cloudera/parcel-repo/

# Verify checksum
cd /opt/cloudera/parcel-repo/
sha1sum -c CDH-${CDP_VERSION}-el7.parcel.sha
```

#### Step 2: Install Core Components

```bash
# Install Hadoop
sudo mkdir -p /opt/cloudera/parcels/CDH
sudo tar -xf /opt/cloudera/parcel-repo/CDH-${CDP_VERSION}-el7.parcel -C /opt/cloudera/parcels/CDH --strip-components=1

# Set permissions
sudo chown -R cloudera-scm:cloudera-scm /opt/cloudera/parcels/CDH
```

## CDP Configuration

### Step 1: Cluster Setup via Cloudera Manager

1. **Add Hosts**: Specify hostnames or IP addresses
2. **Select Repository**: Choose CDP version
3. **Install Parcels**: Download and distribute software
4. **Host Inspector**: Verify system configuration
5. **Select Services**: Choose components to install

### Step 2: Essential Services Configuration

```yaml
# Core Services to Install:
- HDFS (Hadoop Distributed File System)
- YARN (Yet Another Resource Negotiator)
- Zookeeper (Coordination Service)
- Hive (Data Warehouse)
- Impala (Real-time SQL Engine)
- Spark (Analytics Engine)
- Kafka (Stream Processing)
- HBase (NoSQL Database)
- Solr (Search Platform)
```

### Step 3: Security Configuration

#### Enable Kerberos (Production)

```bash
# Install Kerberos client
sudo yum install krb5-workstation krb5-libs -y

# Configure /etc/krb5.conf
sudo cat > /etc/krb5.conf << 'EOF'
[libdefaults]
    default_realm = EXAMPLE.COM
    dns_lookup_realm = false
    dns_lookup_kdc = false
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true

[realms]
    EXAMPLE.COM = {
        kdc = kdc.example.com
        admin_server = kdc.example.com
    }
EOF
```

#### Configure TLS/SSL

```bash
# Generate keystore for each service
sudo keytool -genkeypair -alias $(hostname -f) \
  -keyalg RSA -keysize 2048 -dname "CN=$(hostname -f)" \
  -keypass changeit -keystore /opt/cloudera/security/jks/$(hostname -f).jks \
  -storepass changeit
```

## Service-Specific Configuration

### HDFS Configuration

```xml
<!-- Add to hdfs-site.xml via Cloudera Manager -->
<property>
    <name>dfs.replication</name>
    <value>3</value>
</property>
<property>
    <name>dfs.blocksize</name>
    <value>268435456</value>
</property>
<property>
    <name>dfs.datanode.data.dir</name>
    <value>/data/dfs/dn</value>
</property>
```

### Hive Configuration

```xml
<!-- Hive Metastore configuration -->
<property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:postgresql://localhost:5432/hive_metastore</value>
</property>
<property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>org.postgresql.Driver</value>
</property>
```

### Impala Configuration

```bash
# Impala daemon memory
--mem_limit=4GB

# Impala catalog server
--catalog_service_host=catalog-server-hostname

# Impala state store
--state_store_host=state-store-hostname
```

## CDP Data Services

### Installing Additional Services

#### Cloudera Data Science Workbench (CDSW)

```bash
# Install CDSW via Cloudera Manager
# Navigate to: Add Service → Cloudera Data Science Workbench
# Configure:
# - Master Host: Select master node
# - Docker Block Devices: Configure storage
# - DNS Domain: Set domain for CDSW
```

#### Cloudera Data Flow (CDF)

```bash
# Install NiFi via Cloudera Manager
# Navigate to: Add Service → NiFi
# Configure:
# - NiFi Node: Select installation host
# - Sensitive Properties: Configure encryption
# - Security: Enable if Kerberos is configured
```

### Edge Node Configuration

```bash
# Install client configurations
sudo yum install hadoop-client hive-client impala-client spark-client -y

# Configure environment
export HADOOP_CONF_DIR=/etc/hadoop/conf
export HIVE_CONF_DIR=/etc/hive/conf
export SPARK_CONF_DIR=/etc/spark/conf

# Download client configurations from Cloudera Manager
# Actions → Download Client Configuration
```

## Performance Tuning

### Memory Optimization

```yaml
# YARN Configuration
yarn.nodemanager.resource.memory-mb: 24576
yarn.scheduler.maximum-allocation-mb: 24576
yarn.app.mapreduce.am.resource.mb: 2048

# Spark Configuration  
spark.executor.memory: 4g
spark.executor.cores: 2
spark.sql.adaptive.enabled: true
```

### Disk Optimization

```bash
# Configure multiple data directories
dfs.datanode.data.dir: /data1/dfs/dn,/data2/dfs/dn,/data3/dfs/dn
yarn.nodemanager.local-dirs: /data1/yarn/nm,/data2/yarn/nm,/data3/yarn/nm
```

## Monitoring and Management

### Cloudera Manager Features

1. **Service Management**: Start/stop/restart services
2. **Configuration Management**: Centralized configuration
3. **Health Monitoring**: Service and host health checks
4. **Performance Monitoring**: Metrics and charts
5. **Log Management**: Centralized log viewing
6. **Backup and Recovery**: Automated backup procedures

### Key Metrics to Monitor

```yaml
HDFS:
  - DataNode health
  - NameNode heap usage
  - Block replication status
  
YARN:
  - Resource utilization
  - Job queue status
  - Container allocation

Impala:
  - Query performance
  - Memory usage
  - Catalog refresh status

Hive:
  - HiveServer2 connections
  - Metastore performance
  - Query execution time
```

## Troubleshooting

### Common Issues

#### Service Start Failures

```bash
# Check service logs
sudo tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log

# Check agent connectivity
sudo systemctl status cloudera-scm-agent

# Verify database connectivity
sudo netstat -tlnp | grep 5432  # PostgreSQL
```

#### Memory Issues

```bash
# Check system memory
free -h

# Adjust Java heap sizes in Cloudera Manager
# Service → Configuration → Memory
```

#### Network Issues

```bash
# Check hostname resolution
nslookup $(hostname -f)

# Verify NTP synchronization
ntpq -p

# Check firewall rules
sudo firewall-cmd --list-all
```

### Log Locations

```bash
# Cloudera Manager Server
/var/log/cloudera-scm-server/

# Cloudera Manager Agent
/var/log/cloudera-scm-agent/

# Service Logs (managed by CM)
/var/log/hadoop-hdfs/
/var/log/hadoop-yarn/
/var/log/hive/
/var/log/impala/
/var/log/spark/
```

## CDP vs Open Source Comparison

| Feature | Open Source | CDP Private Cloud |
|---------|-------------|-------------------|
| Installation | Manual | Cloudera Manager |
| Management | Command Line | Web UI |
| Monitoring | Basic tools | Advanced dashboards |
| Security | Manual setup | Integrated security |
| Support | Community | Enterprise support |
| Updates | Manual | Automated updates |
| Backup | Custom scripts | Built-in tools |

## Migration from Open Source

### Assessment

```bash
# Inventory existing services
sudo systemctl list-units --type=service | grep -E "(hadoop|hive|spark)"

# Check current versions
hadoop version
hive --version
spark-shell --version

# Assess data volume
hdfs dfsadmin -report
```

### Migration Steps

1. **Backup existing data**
2. **Install CDP alongside existing installation**
3. **Migrate configurations**
4. **Import data to CDP**
5. **Test applications**
6. **Switch traffic to CDP**
7. **Decommission old installation**

## Licensing and Cost

### CDP Private Cloud Base (Free)
- Core Hadoop ecosystem
- Basic security features
- Community support
- No SLA

### CDP Private Cloud Plus (Licensed)
- Advanced security and governance
- Cloudera Data Engineering
- Cloudera Machine Learning
- Enterprise support
- SLA included

## Next Steps

After CDP installation:

1. **Configure Security**: Enable Kerberos and TLS
2. **Set up Governance**: Configure Atlas and Ranger
3. **Optimize Performance**: Tune services for workload
4. **Implement Monitoring**: Set up alerts and dashboards
5. **Train Users**: Provide access to Cloudera Manager
6. **Develop Applications**: Start building data pipelines

## Conclusion

CDP provides a more integrated and manageable Big Data platform compared to individual Apache components. While it requires more resources and potentially licensing costs, it offers significant advantages in terms of:

- **Easier Management**: Centralized administration
- **Better Security**: Integrated security features  
- **Enterprise Support**: Professional support and SLA
- **Advanced Features**: Data governance, lineage, and compliance

Choose CDP if you need enterprise-grade features, support, and easier management. Stick with open source components if you prefer more control and have the expertise to manage individual services.

For learning purposes, start with the open source components in this workspace, then consider CDP for production deployments.