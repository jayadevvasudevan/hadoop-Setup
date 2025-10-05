# Docker Development Environment for Big Data

This directory contains Docker configurations for setting up isolated Big Data development environments. These containers provide a quick way to experiment with Hadoop, Hive, Impala, and Spark without installing everything on your host system.

## Available Environments

### 1. Hadoop Single Node Cluster
- **File**: `hadoop-single-node/`
- **Components**: Hadoop HDFS, YARN, MapReduce
- **Use Case**: Learning Hadoop basics, HDFS operations

### 2. Hadoop with Hive
- **File**: `hadoop-hive/`
- **Components**: Hadoop + Hive + MySQL Metastore
- **Use Case**: Data warehousing, SQL on Hadoop

### 3. Complete Big Data Stack
- **File**: `complete-stack/`
- **Components**: Hadoop + Hive + Spark + Jupyter
- **Use Case**: Full Big Data development and analysis

### 4. Spark Standalone
- **File**: `spark-standalone/`
- **Components**: Spark + Jupyter + PySpark
- **Use Case**: Spark development and machine learning

## Quick Start

### Prerequisites
- Docker Desktop installed and running
- At least 8GB RAM available for Docker
- 20GB free disk space

### Option 1: Hadoop Single Node
```bash
cd docker/hadoop-single-node
docker-compose up -d
```

### Option 2: Complete Stack
```bash
cd docker/complete-stack
docker-compose up -d
```

## Access Points

Once containers are running, access the following services:

| Service | URL | Description |
|---------|-----|-------------|
| NameNode UI | http://localhost:9870 | HDFS management |
| ResourceManager | http://localhost:8088 | YARN jobs |
| Hive Server2 | http://localhost:10002 | Hive web interface |
| Spark History | http://localhost:18080 | Spark job history |
| Jupyter Notebook | http://localhost:8888 | Interactive development |

## Container Management

### Start Services
```bash
docker-compose up -d
```

### Stop Services
```bash
docker-compose down
```

### View Logs
```bash
docker-compose logs -f [service_name]
```

### Execute Commands
```bash
# Access Hadoop container
docker exec -it hadoop-namenode bash

# Run HDFS commands
docker exec hadoop-namenode hdfs dfs -ls /

# Access Spark container
docker exec -it spark-master bash
```

## Data Persistence

All configurations include persistent volumes to preserve data between container restarts:

- **HDFS Data**: `./volumes/hdfs`
- **Database Data**: `./volumes/mysql`
- **Notebooks**: `./volumes/notebooks`
- **Logs**: `./volumes/logs`

## Networking

All services use a custom Docker network to enable inter-container communication. Services can communicate using container names as hostnames.

## Customization

### Environment Variables
Modify `.env` files in each configuration directory to customize:
- Memory allocation
- Port mappings
- Container versions
- Database passwords

### Adding Services
To add new services, update the `docker-compose.yml` file and add appropriate service definitions.

## Troubleshooting

### Common Issues

1. **Port Conflicts**: Ensure required ports are not in use on host
2. **Memory Issues**: Increase Docker memory allocation
3. **Startup Order**: Some services depend on others (e.g., Hive needs Hadoop)

### Health Checks
```bash
# Check container status
docker-compose ps

# Check service health
curl http://localhost:9870/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus
```

## Best Practices

1. **Resource Management**: Allocate sufficient resources for Docker
2. **Data Backup**: Regularly backup volume data
3. **Version Pinning**: Use specific versions for production-like environments
4. **Security**: Change default passwords in production environments

## Examples and Tutorials

Each configuration includes example datasets and tutorial notebooks to get you started quickly.

See individual directories for specific setup instructions and examples.