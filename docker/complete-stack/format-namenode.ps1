# Hadoop NameNode Formatting Script
# This script formats the NameNode for first-time use

Write-Host "🚀 Formatting Hadoop NameNode..." -ForegroundColor Green

# Check if NameNode is already formatted
$nameNodeDir = "./volumes/namenode"
$versionFile = "$nameNodeDir/current/VERSION"

if (Test-Path $versionFile) {
    Write-Host "⚠️  NameNode appears to already be formatted." -ForegroundColor Yellow
    Write-Host "VERSION file found at: $versionFile" -ForegroundColor Yellow
    
    $response = Read-Host "Do you want to reformat (this will delete all existing data)? [y/N]"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "❌ Formatting cancelled." -ForegroundColor Red
        exit 0
    }
    
    Write-Host "🗑️  Removing existing NameNode data..." -ForegroundColor Yellow
    Remove-Item -Path $nameNodeDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Create volumes directory if it doesn't exist
if (!(Test-Path "./volumes")) {
    New-Item -ItemType Directory -Path "./volumes" -Force
    Write-Host "📁 Created volumes directory" -ForegroundColor Green
}

# Format the NameNode using Docker
Write-Host "🔧 Running NameNode format command..." -ForegroundColor Cyan

try {
    docker run --rm `
        -v "${PWD}/volumes/namenode:/hadoop/dfs/name" `
        -e CLUSTER_NAME=bigdata-cluster `
        -e CORE_CONF_fs_defaultFS=hdfs://namenode:9000 `
        -e CORE_CONF_hadoop_http_staticuser_user=root `
        -e HDFS_CONF_dfs_namenode_name_dir=/hadoop/dfs/name `
        -e HDFS_CONF_dfs_datanode_data_dir=/hadoop/dfs/data `
        -e HDFS_CONF_dfs_replication=1 `
        -e HDFS_CONF_dfs_permissions_enabled=false `
        -e HDFS_CONF_dfs_webhdfs_enabled=true `
        -e HDFS_CONF_dfs_namenode_datanode_registration_ip___hostname___check=false `
        bde2020/hadoop-namenode:2.0.0-hadoop3.2.1-java8 `
        hdfs namenode -format -force

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ NameNode formatted successfully!" -ForegroundColor Green
        Write-Host "🚀 You can now start the Big Data stack with: docker-compose up -d" -ForegroundColor Cyan
    } else {
        Write-Host "❌ NameNode formatting failed!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error running format command: $_" -ForegroundColor Red
    exit 1
}