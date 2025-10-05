# PowerShell Installation Script for Big Data Stack
# This script installs and configures Hadoop, Hive, Spark, and related tools on Windows

param(
    [string]$InstallPath = "C:\BigData",
    [switch]$SkipDownloads,
    [switch]$ConfigureOnly,
    [switch]$Verbose
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Global variables
$LogFile = "$env:TEMP\bigdata-install.log"
$DownloadPath = "$env:TEMP\bigdata-downloads"

# Create log file
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Output $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Download file with progress
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$Description
    )
    
    Write-Log "Downloading $Description from $Url"
    
    try {
        # Use BITS if available, otherwise use WebClient
        if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
            Start-BitsTransfer -Source $Url -Destination $OutputPath -DisplayName $Description
        } else {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($Url, $OutputPath)
            $webClient.Dispose()
        }
        Write-Log "Successfully downloaded $Description"
    }
    catch {
        Write-Log "Failed to download $Description`: $_" "ERROR"
        throw
    }
}

# Extract archive
function Extract-Archive {
    param(
        [string]$ArchivePath,
        [string]$DestinationPath,
        [string]$Description
    )
    
    Write-Log "Extracting $Description to $DestinationPath"
    
    try {
        if ($ArchivePath.EndsWith('.zip')) {
            Expand-Archive -Path $ArchivePath -DestinationPath $DestinationPath -Force
        } else {
            # For .tar.gz files, use 7-Zip if available
            $sevenZip = Get-Command "7z.exe" -ErrorAction SilentlyContinue
            if ($sevenZip) {
                & "7z.exe" x $ArchivePath -o"$DestinationPath" -y
            } else {
                Write-Log "7-Zip not found. Please install 7-Zip or extract $ArchivePath manually" "ERROR"
                throw "7-Zip required for .tar.gz extraction"
            }
        }
        Write-Log "Successfully extracted $Description"
    }
    catch {
        Write-Log "Failed to extract $Description`: $_" "ERROR"
        throw
    }
}

# Set environment variable
function Set-BigDataEnvironmentVariable {
    param(
        [string]$Name,
        [string]$Value,
        [string]$Target = "Machine"
    )
    
    Write-Log "Setting environment variable $Name = $Value"
    [Environment]::SetEnvironmentVariable($Name, $Value, $Target)
}

# Add to PATH
function Add-ToPath {
    param([string]$NewPath)
    
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($currentPath -notlike "*$NewPath*") {
        $newPathValue = "$currentPath;$NewPath"
        Set-BigDataEnvironmentVariable -Name "PATH" -Value $newPathValue
        Write-Log "Added $NewPath to PATH"
    }
}

# Check Java installation
function Test-JavaInstallation {
    try {
        $javaVersion = & java -version 2>&1
        if ($javaVersion -match "openjdk|java version") {
            Write-Log "Java is already installed: $($javaVersion[0])"
            return $true
        }
    }
    catch {
        Write-Log "Java not found or not working properly"
    }
    return $false
}

# Install Java
function Install-Java {
    Write-Log "Installing OpenJDK 11..."
    
    if (-not $SkipDownloads) {
        $javaUrl = "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.20%2B8/OpenJDK11U-jdk_x64_windows_hotspot_11.0.20_8.msi"
        $javaInstaller = "$DownloadPath\openjdk-11.msi"
        
        Download-File -Url $javaUrl -OutputPath $javaInstaller -Description "OpenJDK 11"
        
        Write-Log "Installing Java..."
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $javaInstaller, "/quiet", "/norestart" -Wait
    }
    
    # Set JAVA_HOME
    $javaHome = "C:\Program Files\Eclipse Adoptium\jdk-11.0.20.8-hotspot"
    if (Test-Path $javaHome) {
        Set-BigDataEnvironmentVariable -Name "JAVA_HOME" -Value $javaHome
        Add-ToPath "$javaHome\bin"
        Write-Log "Java installation completed"
    } else {
        Write-Log "Java installation may have failed - JAVA_HOME not found" "ERROR"
    }
}

# Install Hadoop
function Install-Hadoop {
    Write-Log "Installing Hadoop..."
    
    $hadoopVersion = "3.3.4"
    $hadoopHome = "$InstallPath\hadoop"
    
    if (-not $SkipDownloads) {
        $hadoopUrl = "https://downloads.apache.org/hadoop/common/hadoop-$hadoopVersion/hadoop-$hadoopVersion.tar.gz"
        $hadoopArchive = "$DownloadPath\hadoop-$hadoopVersion.tar.gz"
        
        Download-File -Url $hadoopUrl -OutputPath $hadoopArchive -Description "Hadoop $hadoopVersion"
        Extract-Archive -ArchivePath $hadoopArchive -DestinationPath $InstallPath -Description "Hadoop"
        
        # Rename directory
        if (Test-Path "$InstallPath\hadoop-$hadoopVersion") {
            Rename-Item "$InstallPath\hadoop-$hadoopVersion" "hadoop"
        }
    }
    
    # Set environment variables
    Set-BigDataEnvironmentVariable -Name "HADOOP_HOME" -Value $hadoopHome
    Set-BigDataEnvironmentVariable -Name "HADOOP_CONF_DIR" -Value "$hadoopHome\etc\hadoop"
    Add-ToPath "$hadoopHome\bin"
    Add-ToPath "$hadoopHome\sbin"
    
    Write-Log "Hadoop installation completed"
}

# Install Hive
function Install-Hive {
    Write-Log "Installing Hive..."
    
    $hiveVersion = "3.1.3"
    $hiveHome = "$InstallPath\hive"
    
    if (-not $SkipDownloads) {
        $hiveUrl = "https://downloads.apache.org/hive/hive-$hiveVersion/apache-hive-$hiveVersion-bin.tar.gz"
        $hiveArchive = "$DownloadPath\apache-hive-$hiveVersion-bin.tar.gz"
        
        Download-File -Url $hiveUrl -OutputPath $hiveArchive -Description "Hive $hiveVersion"
        Extract-Archive -ArchivePath $hiveArchive -DestinationPath $InstallPath -Description "Hive"
        
        # Rename directory
        if (Test-Path "$InstallPath\apache-hive-$hiveVersion-bin") {
            Rename-Item "$InstallPath\apache-hive-$hiveVersion-bin" "hive"
        }
    }
    
    # Set environment variables
    Set-BigDataEnvironmentVariable -Name "HIVE_HOME" -Value $hiveHome
    Set-BigDataEnvironmentVariable -Name "HIVE_CONF_DIR" -Value "$hiveHome\conf"
    Add-ToPath "$hiveHome\bin"
    
    Write-Log "Hive installation completed"
}

# Install Spark
function Install-Spark {
    Write-Log "Installing Spark..."
    
    $sparkVersion = "3.4.1"
    $sparkHome = "$InstallPath\spark"
    
    if (-not $SkipDownloads) {
        $sparkUrl = "https://downloads.apache.org/spark/spark-$sparkVersion/spark-$sparkVersion-bin-hadoop3.tgz"
        $sparkArchive = "$DownloadPath\spark-$sparkVersion-bin-hadoop3.tgz"
        
        Download-File -Url $sparkUrl -OutputPath $sparkArchive -Description "Spark $sparkVersion"
        Extract-Archive -ArchivePath $sparkArchive -DestinationPath $InstallPath -Description "Spark"
        
        # Rename directory
        if (Test-Path "$InstallPath\spark-$sparkVersion-bin-hadoop3") {
            Rename-Item "$InstallPath\spark-$sparkVersion-bin-hadoop3" "spark"
        }
    }
    
    # Set environment variables
    Set-BigDataEnvironmentVariable -Name "SPARK_HOME" -Value $sparkHome
    Set-BigDataEnvironmentVariable -Name "SPARK_CONF_DIR" -Value "$sparkHome\conf"
    Set-BigDataEnvironmentVariable -Name "PYSPARK_PYTHON" -Value "python"
    Set-BigDataEnvironmentVariable -Name "PYSPARK_DRIVER_PYTHON" -Value "python"
    Add-ToPath "$sparkHome\bin"
    Add-ToPath "$sparkHome\sbin"
    
    Write-Log "Spark installation completed"
}

# Create configuration files
function Create-ConfigurationFiles {
    Write-Log "Creating configuration files..."
    
    # Create data directories
    $dataDir = "$InstallPath\data"
    New-Item -ItemType Directory -Path "$dataDir\hdfs\namenode" -Force | Out-Null
    New-Item -ItemType Directory -Path "$dataDir\hdfs\datanode" -Force | Out-Null
    New-Item -ItemType Directory -Path "$dataDir\logs" -Force | Out-Null
    
    # Hadoop configuration
    $hadoopConfDir = "$InstallPath\hadoop\etc\hadoop"
    
    # core-site.xml
    $coreSiteXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>$dataDir\tmp</value>
    </property>
</configuration>
"@
    $coreSiteXml | Out-File -FilePath "$hadoopConfDir\core-site.xml" -Encoding UTF8
    
    # hdfs-site.xml
    $hdfsSiteXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:///$($dataDir.Replace('\', '/'))/hdfs/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:///$($dataDir.Replace('\', '/'))/hdfs/datanode</value>
    </property>
</configuration>
"@
    $hdfsSiteXml | Out-File -FilePath "$hadoopConfDir\hdfs-site.xml" -Encoding UTF8
    
    Write-Log "Configuration files created"
}

# Test installation
function Test-Installation {
    Write-Log "Testing installation..."
    
    $testResults = @()
    
    # Test Java
    try {
        $javaVersion = & java -version 2>&1
        $testResults += "✓ Java: OK ($($javaVersion[0]))"
    }
    catch {
        $testResults += "✗ Java: FAILED"
    }
    
    # Test Hadoop
    try {
        $hadoopVersion = & hadoop version 2>&1
        $testResults += "✓ Hadoop: OK"
    }
    catch {
        $testResults += "✗ Hadoop: FAILED"
    }
    
    # Test Hive
    try {
        $hiveVersion = & hive --version 2>&1
        $testResults += "✓ Hive: OK"
    }
    catch {
        $testResults += "✗ Hive: FAILED"
    }
    
    # Test Spark
    try {
        $sparkVersion = & spark-shell --version 2>&1
        $testResults += "✓ Spark: OK"
    }
    catch {
        $testResults += "✗ Spark: FAILED"
    }
    
    Write-Log "Installation test results:"
    $testResults | ForEach-Object { Write-Log $_ }
    
    return $testResults
}

# Main installation function
function Install-BigDataStack {
    Write-Log "Starting Big Data Stack installation..."
    Write-Log "Installation path: $InstallPath"
    Write-Log "Skip downloads: $SkipDownloads"
    Write-Log "Configure only: $ConfigureOnly"
    
    # Check administrator privileges
    if (-not (Test-Administrator)) {
        Write-Log "This script requires administrator privileges" "ERROR"
        throw "Administrator privileges required"
    }
    
    # Create directories
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null
    
    # Install components
    if (-not $ConfigureOnly) {
        if (-not (Test-JavaInstallation)) {
            Install-Java
        }
        Install-Hadoop
        Install-Hive
        Install-Spark
    }
    
    # Create configuration
    Create-ConfigurationFiles
    
    # Test installation
    $testResults = Test-Installation
    
    Write-Log "Installation completed!"
    Write-Log "Please restart your PowerShell session to use the new environment variables"
    Write-Log "Log file: $LogFile"
    
    return $testResults
}

# Script execution
try {
    Write-Log "BigData Stack Installation Script Started"
    $results = Install-BigDataStack
    
    Write-Output ""
    Write-Output "Installation Summary:"
    Write-Output "===================="
    $results | ForEach-Object { Write-Output $_ }
    Write-Output ""
    Write-Output "Next steps:"
    Write-Output "1. Restart PowerShell session"
    Write-Output "2. Run: .\Start-Services.ps1"
    Write-Output "3. Check: .\Test-Installation.ps1"
    
}
catch {
    Write-Log "Installation failed: $_" "ERROR"
    Write-Error "Installation failed. Check log file: $LogFile"
    exit 1
}