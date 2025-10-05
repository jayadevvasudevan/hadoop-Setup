# Hadoop and Big Data Installation Scripts

This directory contains automation scripts for installing and configuring the Big Data stack on your edge node.

## Available Scripts

### Installation Scripts
- `install-java.sh` - Install OpenJDK 11
- `install-hadoop.sh` - Download and configure Hadoop
- `install-hive.sh` - Download and configure Hive with MySQL
- `install-spark.sh` - Download and configure Spark
- `setup-environment.sh` - Configure environment variables

### Management Scripts
- `start-all-services.sh` - Start all Big Data services
- `stop-all-services.sh` - Stop all Big Data services
- `status-check.sh` - Check status of all services
- `cluster-monitor.sh` - Monitor cluster health and performance

### Data Management Scripts
- `create-sample-data.sh` - Generate sample datasets
- `backup-hdfs.sh` - Backup HDFS data
- `restore-hdfs.sh` - Restore HDFS data from backup

### PowerShell Scripts (Windows)
- `Install-BigDataStack.ps1` - Complete installation for Windows
- `Start-Services.ps1` - Start services on Windows
- `Test-Installation.ps1` - Verify installation

## Usage

### Linux/Unix Systems

```bash
# Make scripts executable
chmod +x *.sh

# Run installation (requires sudo)
sudo ./install-prerequisites.sh
./install-hadoop.sh
./install-hive.sh
./install-spark.sh

# Start services
./start-all-services.sh

# Check status
./status-check.sh
```

### Windows Systems

```powershell
# Set execution policy (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run installation
./Install-BigDataStack.ps1

# Start services
./Start-Services.ps1

# Test installation
./Test-Installation.ps1
```

## Prerequisites

Before running these scripts:

1. **Linux**: Ubuntu 18.04+, CentOS 7+, or similar
2. **Windows**: Windows 10/11 with PowerShell 5.1+
3. **Memory**: At least 8GB RAM
4. **Storage**: At least 50GB free space
5. **Network**: Internet connection for downloads

## Configuration

Scripts use configuration files in the `configs/` directory. Modify these files to customize your installation:

- `hadoop.conf` - Hadoop cluster settings
- `hive.conf` - Hive database and metastore settings
- `spark.conf` - Spark memory and execution settings

## Logging

All scripts generate logs in `/tmp/bigdata-install.log` (Linux) or `$env:TEMP\bigdata-install.log` (Windows).

## Support

If you encounter issues:

1. Check the installation logs
2. Verify prerequisites are met
3. Ensure sufficient system resources
4. Review the troubleshooting guides in `docs/`

## Contributing

To add new scripts:

1. Follow the existing naming convention
2. Add logging and error handling
3. Update this README
4. Test on clean systems