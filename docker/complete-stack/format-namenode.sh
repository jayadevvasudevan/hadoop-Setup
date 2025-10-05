#!/bin/bash
# Hadoop NameNode Formatting Script for WSL
# This script formats the NameNode for first-time use

echo "🚀 Formatting Hadoop NameNode..."

# Check if NameNode is already formatted
NAMENODE_DIR="./volumes/namenode"
VERSION_FILE="$NAMENODE_DIR/current/VERSION"

if [ -f "$VERSION_FILE" ]; then
    echo "⚠️  NameNode appears to already be formatted."
    echo "VERSION file found at: $VERSION_FILE"
    
    read -p "Do you want to reformat (this will delete all existing data)? [y/N]: " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "❌ Formatting cancelled."
        exit 0
    fi
    
    echo "🗑️  Removing existing NameNode data..."
    rm -rf "$NAMENODE_DIR"
fi

# Create volumes directory if it doesn't exist
if [ ! -d "./volumes" ]; then
    mkdir -p "./volumes"
    echo "📁 Created volumes directory"
fi

# Format the NameNode using Docker
echo "🔧 Running NameNode format command..."

docker run --rm \
    -v "$(pwd)/volumes/namenode:/hadoop/dfs/name" \
    -e CLUSTER_NAME=bigdata-cluster \
    -e CORE_CONF_fs_defaultFS=hdfs://namenode:9000 \
    -e CORE_CONF_hadoop_http_staticuser_user=root \
    -e HDFS_CONF_dfs_namenode_name_dir=/hadoop/dfs/name \
    -e HDFS_CONF_dfs_datanode_data_dir=/hadoop/dfs/data \
    -e HDFS_CONF_dfs_replication=1 \
    -e HDFS_CONF_dfs_permissions_enabled=false \
    -e HDFS_CONF_dfs_webhdfs_enabled=true \
    -e HDFS_CONF_dfs_namenode_datanode_registration_ip___hostname___check=false \
    bde2020/hadoop-namenode:2.0.0-hadoop3.2.1-java8 \
    hdfs namenode -format -force

if [ $? -eq 0 ]; then
    echo "✅ NameNode formatted successfully!"
    echo "🚀 You can now start the Big Data stack with: docker-compose up -d"
else
    echo "❌ NameNode formatting failed!"
    exit 1
fi