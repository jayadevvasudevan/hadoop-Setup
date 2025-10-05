# Prerequisites for Hadoop Edge Node Setup

Before setting up your Hadoop edge node with Big Data technologies, ensure your system meets the following requirements and has the necessary software installed.

## System Requirements

### Hardware Requirements
- **RAM**: Minimum 8GB (Recommended: 16GB or more)
- **Storage**: At least 50GB free space (SSD recommended for better performance)
- **CPU**: Multi-core processor (minimum 4 cores recommended)
- **Network**: Stable internet connection for downloads

### Operating System Support
- **Linux**: Ubuntu 18.04+, CentOS 7+, Red Hat Enterprise Linux 7+
- **Windows**: Windows 10/11 with WSL2 (Windows Subsystem for Linux)
- **macOS**: macOS 10.14+ (with limitations)

## Required Software

### 1. Java Development Kit (JDK)

Hadoop ecosystem requires Java 8 or Java 11. We recommend **OpenJDK 11**.

#### Linux Installation:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install openjdk-11-jdk

# CentOS/RHEL
sudo yum install java-11-openjdk-devel
```

#### Windows Installation:
1. Download OpenJDK 11 from [Adoptium](https://adoptium.net/)
2. Install the MSI package
3. Set JAVA_HOME environment variable

#### Verification:
```bash
java -version
javac -version
echo $JAVA_HOME
```

### 2. SSH Server and Client

SSH is required for Hadoop cluster communication.

#### Linux:
```bash
# Ubuntu/Debian
sudo apt install openssh-server openssh-client

# CentOS/RHEL
sudo yum install openssh-server openssh-clients
```

#### Windows:
- Enable OpenSSH through Windows Features
- Or use WSL2 with SSH installed

### 3. Python (for Spark and data processing)

Install Python 3.7+ with pip:

```bash
# Linux
sudo apt install python3 python3-pip  # Ubuntu/Debian
sudo yum install python3 python3-pip  # CentOS/RHEL

# Verify installation
python3 --version
pip3 --version
```

### 4. Scala (for Spark development)

```bash
# Using package manager
sudo apt install scala  # Ubuntu/Debian

# Or download from official site
wget https://downloads.lightbend.com/scala/2.13.10/scala-2.13.10.tgz
tar xzf scala-2.13.10.tgz
sudo mv scala-2.13.10 /opt/scala
```

### 5. Docker (for containerized development)

#### Linux:
```bash
# Ubuntu
sudo apt update
sudo apt install docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

#### Windows:
- Install Docker Desktop from [docker.com](https://docker.com)

### 6. Git (for version control)

```bash
# Linux
sudo apt install git  # Ubuntu/Debian
sudo yum install git   # CentOS/RHEL

# Verify
git --version
```

## Environment Variables

Create or update your shell profile (`.bashrc`, `.zshrc`, or `.profile`):

```bash
# Java
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64  # Adjust path as needed
export PATH=$PATH:$JAVA_HOME/bin

# Scala (if installed manually)
export SCALA_HOME=/opt/scala
export PATH=$PATH:$SCALA_HOME/bin

# Python
export PYTHONPATH=$PYTHONPATH:.

# Reload profile
source ~/.bashrc
```

## Network Configuration

### Firewall Settings

Ensure the following ports are accessible:

| Service | Port | Description |
|---------|------|-------------|
| SSH | 22 | Remote access |
| Hadoop NameNode | 9000, 9870 | HDFS access |
| Hadoop DataNode | 9864 | Data transfer |
| YARN ResourceManager | 8088 | Job management |
| Hive Metastore | 9083 | Hive metadata |
| HiveServer2 | 10000 | Hive SQL interface |
| Impala Daemon | 21000 | Impala queries |
| Impala StateStore | 25010 | Impala coordination |
| Spark History Server | 18080 | Spark job history |

### Hosts Configuration

Update `/etc/hosts` file:

```bash
# Add entries for your cluster nodes
127.0.0.1 localhost
192.168.1.100 hadoop-master
192.168.1.101 hadoop-worker1
192.168.1.102 hadoop-worker2
```

## User Setup

### Create Hadoop User

```bash
# Create dedicated user for Hadoop
sudo adduser hadoop
sudo usermod -aG sudo hadoop

# Switch to hadoop user
su - hadoop

# Generate SSH keys for passwordless access
ssh-keygen -t rsa -P ""
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
```

## Directory Structure

Create necessary directories:

```bash
# Create Hadoop directories
sudo mkdir -p /opt/hadoop
sudo mkdir -p /opt/hive
sudo mkdir -p /opt/impala
sudo mkdir -p /opt/spark
sudo mkdir -p /opt/scala

# Create data directories
sudo mkdir -p /data/hadoop/hdfs/namenode
sudo mkdir -p /data/hadoop/hdfs/datanode
sudo mkdir -p /data/hadoop/logs

# Set permissions
sudo chown -R hadoop:hadoop /opt/hadoop /opt/hive /opt/impala /opt/spark /data/hadoop
```

## Verification Checklist

Before proceeding to the next installation step, verify:

- [ ] Java 11 is installed and JAVA_HOME is set
- [ ] SSH server is running and accessible
- [ ] Python 3.7+ is installed with pip
- [ ] Scala is installed (if installing manually)
- [ ] Docker is installed and running
- [ ] Git is installed
- [ ] Required directories are created with proper permissions
- [ ] Network ports are accessible
- [ ] Hadoop user is created with SSH keys

## Next Steps

Once all prerequisites are met, choose your installation path:

### Option 1: Individual Components (Learning Path)
1. **[Hadoop Installation](02-hadoop-installation.md)** - Core Hadoop setup
2. **[Hive Installation](03-hive-installation.md)** - Data warehousing
3. **[Impala Installation](04-impala-installation.md)** - Real-time queries
4. **[Spark Installation](05-spark-installation.md)** - Analytics engine

### Option 2: Enterprise Platform
5. **[CDP Installation](06-cdp-installation.md)** - Cloudera Data Platform (Enterprise)

### Option 3: Containerized Development
- **[Docker Environment](../docker/README.md)** - Quick setup with containers

## Troubleshooting

### Common Issues

1. **Java not found**: Check JAVA_HOME path and PATH variable
2. **SSH connection refused**: Ensure SSH server is running
3. **Permission denied**: Check directory ownership and permissions
4. **Port conflicts**: Verify no other services are using required ports

### Getting Help

- Check logs in `/var/log/` for system errors
- Use `systemctl status <service>` to check service status
- Verify environment variables with `env | grep JAVA`
- Test network connectivity with `telnet <host> <port>`