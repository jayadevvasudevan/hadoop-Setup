# Hadoop HDFS Tutorial

This tutorial provides hands-on experience with Hadoop Distributed File System (HDFS), the storage layer of the Hadoop ecosystem.

## Learning Objectives

After completing this tutorial, you will be able to:
- Navigate and manage files in HDFS
- Understand HDFS architecture and concepts
- Perform basic and advanced HDFS operations
- Monitor HDFS health and performance
- Work with HDFS permissions and quotas

## Prerequisites

- Hadoop installed and running
- Basic command line knowledge
- Understanding of distributed file systems

## HDFS Basics

### HDFS Architecture Overview

HDFS follows a master-slave architecture:
- **NameNode**: Master node that manages metadata
- **DataNode**: Worker nodes that store actual data
- **Secondary NameNode**: Assists primary NameNode with checkpoints

### Key Concepts

- **Block**: Default size 128MB (configurable)
- **Replication**: Default factor of 3 for fault tolerance
- **Rack Awareness**: Optimizes data placement across racks

## Basic HDFS Commands

### 1. File System Navigation

```bash
# List root directory
hdfs dfs -ls /

# List with detailed information
hdfs dfs -ls -l /

# List recursively
hdfs dfs -ls -R /user

# Show current working directory (not available in HDFS, always use full paths)
hdfs dfs -pwd
```

### 2. Creating Directories

```bash
# Create a single directory
hdfs dfs -mkdir /user/training

# Create nested directories
hdfs dfs -mkdir -p /user/training/data/input

# Create multiple directories
hdfs dfs -mkdir /user/training/logs /user/training/output
```

### 3. File Upload and Download

```bash
# Upload a single file
echo "Hello HDFS!" > /tmp/test.txt
hdfs dfs -put /tmp/test.txt /user/training/

# Upload multiple files
hdfs dfs -put /tmp/*.txt /user/training/data/

# Upload with different name
hdfs dfs -put /tmp/test.txt /user/training/renamed.txt

# Copy from local with overwrite
hdfs dfs -copyFromLocal -f /tmp/test.txt /user/training/

# Download a file
hdfs dfs -get /user/training/test.txt /tmp/downloaded.txt

# Download entire directory
hdfs dfs -get /user/training/data /tmp/hdfs_data

# Copy to local
hdfs dfs -copyToLocal /user/training/test.txt /tmp/copied.txt
```

### 4. File Operations

```bash
# Copy files within HDFS
hdfs dfs -cp /user/training/test.txt /user/training/backup.txt

# Move/rename files
hdfs dfs -mv /user/training/test.txt /user/training/moved.txt

# Remove files
hdfs dfs -rm /user/training/backup.txt

# Remove directories
hdfs dfs -rm -r /user/training/data/temp

# Remove files safely (move to trash)
hdfs dfs -rm -skipTrash /user/training/unwanted.txt
```

### 5. File Content Operations

```bash
# Display file content
hdfs dfs -cat /user/training/test.txt

# Display last 1KB of file
hdfs dfs -tail /user/training/large_file.txt

# Display first few lines
hdfs dfs -cat /user/training/data.txt | head -10

# Count lines, words, characters
hdfs dfs -cat /user/training/data.txt | wc

# Search within files
hdfs dfs -cat /user/training/logs.txt | grep "ERROR"
```

## Practical Exercise 1: Basic File Operations

Let's create a sample dataset and practice basic operations:

```bash
# Create sample data
cat > /tmp/employees.csv << 'EOF'
id,name,department,salary,hire_date
1,John Doe,Engineering,75000,2020-01-15
2,Jane Smith,Marketing,65000,2020-03-10
3,Bob Johnson,Engineering,80000,2019-08-20
4,Alice Brown,Sales,55000,2021-02-05
5,Charlie Wilson,Engineering,70000,2020-11-30
6,Diana Lee,Marketing,60000,2021-04-12
7,Frank Miller,Sales,58000,2020-07-18
8,Grace Chen,Engineering,85000,2019-12-03
9,Henry Davis,Marketing,62000,2021-01-25
10,Ivy Wang,Sales,56000,2020-09-14
EOF

# Create sample log data
cat > /tmp/application.log << 'EOF'
2023-10-01 10:00:01 INFO Starting application
2023-10-01 10:00:02 INFO Loading configuration
2023-10-01 10:00:03 DEBUG Configuration loaded successfully
2023-10-01 10:00:04 INFO Connecting to database
2023-10-01 10:00:05 ERROR Failed to connect to database
2023-10-01 10:00:06 WARN Retrying database connection
2023-10-01 10:00:07 INFO Database connection established
2023-10-01 10:00:08 INFO Application ready
2023-10-01 10:01:00 ERROR Unexpected error in processing
2023-10-01 10:01:01 WARN Performance degradation detected
EOF

# Upload to HDFS
hdfs dfs -mkdir -p /user/training/datasets
hdfs dfs -put /tmp/employees.csv /user/training/datasets/
hdfs dfs -put /tmp/application.log /user/training/datasets/

# Verify upload
hdfs dfs -ls -l /user/training/datasets/

# Practice operations
echo "=== File Content ==="
hdfs dfs -cat /user/training/datasets/employees.csv

echo -e "\n=== File Statistics ==="
hdfs dfs -cat /user/training/datasets/employees.csv | wc

echo -e "\n=== Search Operations ==="
hdfs dfs -cat /user/training/datasets/application.log | grep "ERROR"

echo -e "\n=== Engineering Employees ==="
hdfs dfs -cat /user/training/datasets/employees.csv | grep "Engineering"
```

## Advanced HDFS Operations

### 6. File Permissions and Ownership

```bash
# Check file permissions
hdfs dfs -ls -l /user/training/

# Change permissions (similar to chmod)
hdfs dfs -chmod 755 /user/training/datasets/employees.csv

# Change ownership
hdfs dfs -chown hadoop:hadoop /user/training/datasets/

# Change group ownership
hdfs dfs -chgrp supergroup /user/training/datasets/employees.csv

# Set permissions recursively
hdfs dfs -chmod -R 644 /user/training/datasets/
```

### 7. File System Information

```bash
# Check file system usage
hdfs dfs -df -h

# Check specific directory usage
hdfs dfs -du -h /user/training/

# Check disk usage summary
hdfs dfs -du -s -h /user/training/

# Count files and directories
hdfs dfs -count /user/training/

# Find files by name pattern
hdfs dfs -find /user/training/ -name "*.csv"

# Get file checksum
hdfs dfs -checksum /user/training/datasets/employees.csv
```

### 8. Block and Replication Management

```bash
# View file block information
hdfs fsck /user/training/datasets/employees.csv -files -blocks -locations

# Set replication factor
hdfs dfs -setrep 2 /user/training/datasets/employees.csv

# Set replication recursively
hdfs dfs -setrep -R 3 /user/training/datasets/

# Check replication status
hdfs fsck /user/training/datasets/ -files -blocks
```

## Practical Exercise 2: Working with Large Files

```bash
# Generate a larger dataset
cat > /tmp/generate_large_data.py << 'EOF'
import random
import csv

# Generate large sales dataset
with open('/tmp/sales_data.csv', 'w', newline='') as csvfile:
    fieldnames = ['transaction_id', 'customer_id', 'product_id', 'quantity', 'price', 'date']
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    
    writer.writeheader()
    for i in range(1, 100001):  # 100,000 records
        writer.writerow({
            'transaction_id': i,
            'customer_id': random.randint(1000, 9999),
            'product_id': random.randint(1, 1000),
            'quantity': random.randint(1, 10),
            'price': round(random.uniform(10.0, 500.0), 2),
            'date': f"2023-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
        })

print("Generated 100,000 sales records")
EOF

python3 /tmp/generate_large_data.py

# Upload large file
hdfs dfs -put /tmp/sales_data.csv /user/training/datasets/

# Analyze the large file
echo "=== File Information ==="
hdfs dfs -ls -l /user/training/datasets/sales_data.csv

echo -e "\n=== Block Information ==="
hdfs fsck /user/training/datasets/sales_data.csv -files -blocks

echo -e "\n=== First 10 Lines ==="
hdfs dfs -cat /user/training/datasets/sales_data.csv | head -10

echo -e "\n=== Last 10 Lines ==="
hdfs dfs -tail /user/training/datasets/sales_data.csv

echo -e "\n=== Record Count ==="
hdfs dfs -cat /user/training/datasets/sales_data.csv | wc -l

echo -e "\n=== High Value Transactions ==="
hdfs dfs -cat /user/training/datasets/sales_data.csv | awk -F',' '$5 > 400' | head -5
```

## HDFS Administration Commands

### 9. Cluster Health and Monitoring

```bash
# Check cluster health
hdfs dfsadmin -report

# Check safe mode status
hdfs dfsadmin -safemode get

# Enter/exit safe mode (admin only)
hdfs dfsadmin -safemode enter
hdfs dfsadmin -safemode leave

# Refresh nodes
hdfs dfsadmin -refreshNodes

# Get NameNode information
hdfs getconf -namenodes

# Check configuration
hdfs getconf -confKey dfs.replication
```

### 10. File System Check and Repair

```bash
# Check file system integrity
hdfs fsck / -files -blocks -locations

# Check specific directory
hdfs fsck /user/training/ -files -blocks

# List corrupt files
hdfs fsck / -list-corruptfileblocks

# Delete corrupt files (careful!)
hdfs fsck / -delete

# Move corrupt files to lost+found
hdfs fsck / -move
```

## Practical Exercise 3: Backup and Recovery

```bash
# Create backup procedures
echo "=== Creating Backup Strategy ==="

# 1. Create backup directory structure
hdfs dfs -mkdir -p /backups/daily/$(date +%Y-%m-%d)
hdfs dfs -mkdir -p /backups/weekly/$(date +%Y-W%U)

# 2. Copy important data to backup location
hdfs dfs -cp -p /user/training/datasets/ /backups/daily/$(date +%Y-%m-%d)/

# 3. Verify backup
echo "Backup verification:"
hdfs dfs -ls -R /backups/daily/$(date +%Y-%m-%d)/

# 4. Create archive for long-term storage
hadoop archive -archiveName training_backup_$(date +%Y%m%d).har -p /backups/daily/$(date +%Y-%m-%d) datasets /backups/archives/

# 5. List archive contents
hdfs dfs -ls /backups/archives/training_backup_$(date +%Y%m%d).har

# 6. Extract from archive (if needed)
hdfs dfs -cp /backups/archives/training_backup_$(date +%Y%m%d).har/datasets/* /tmp/restored/
```

## Performance Optimization

### 11. Optimizing HDFS Performance

```bash
# Check current block size
hdfs getconf -confKey dfs.blocksize

# Upload file with custom block size
hdfs dfs -D dfs.blocksize=67108864 -put /tmp/sales_data.csv /user/training/datasets/sales_64mb.csv

# Set higher replication for critical files
hdfs dfs -setrep 5 /user/training/datasets/employees.csv

# Use distcp for efficient copying
hadoop distcp /user/training/datasets/ /user/training/backup/

# Balancer to distribute blocks evenly
hdfs balancer -threshold 10
```

### 12. Monitoring and Troubleshooting

```bash
# Create monitoring script
cat > /tmp/hdfs_monitor.sh << 'EOF'
#!/bin/bash

echo "=== HDFS Health Check - $(date) ==="

echo -e "\n1. Cluster Summary:"
hdfs dfsadmin -report | head -20

echo -e "\n2. NameNode Status:"
curl -s http://localhost:9870/jmx?qry=Hadoop:service=NameNode,name=FSNamesystem | python3 -m json.tool | grep -E "(Total|Used|Available|PercentUsed)"

echo -e "\n3. DataNode Status:"
curl -s http://localhost:9864/jmx?qry=java.lang:type=Memory | python3 -m json.tool | grep -E "(HeapMemoryUsage|NonHeapMemoryUsage)" | head -5

echo -e "\n4. Top 10 Largest Files:"
hdfs dfs -du /user/ 2>/dev/null | sort -nr | head -10

echo -e "\n5. File System Errors:"
hdfs fsck / -files 2>&1 | grep -E "(CORRUPT|MISSING)" | head -5

echo -e "\n6. Safe Mode Status:"
hdfs dfsadmin -safemode get
EOF

chmod +x /tmp/hdfs_monitor.sh
/tmp/hdfs_monitor.sh
```

## Data Analysis with HDFS

### 13. Processing Data Directly from HDFS

```bash
# Analyze sales data using command line tools
echo "=== Sales Data Analysis ==="

# Total sales by month
echo "Monthly sales totals:"
hdfs dfs -cat /user/training/datasets/sales_data.csv | \
  awk -F',' 'NR>1 {month=substr($6,6,2); sales[month]+=$4*$5} END {for(m in sales) print "Month " m ": $" sales[m]}' | \
  sort

# Top 10 customers by transaction count
echo -e "\nTop 10 customers by transaction count:"
hdfs dfs -cat /user/training/datasets/sales_data.csv | \
  awk -F',' 'NR>1 {count[$2]++} END {for(c in count) print count[c], c}' | \
  sort -nr | head -10

# Average transaction value
echo -e "\nAverage transaction value:"
hdfs dfs -cat /user/training/datasets/sales_data.csv | \
  awk -F',' 'NR>1 {sum+=$4*$5; count++} END {print "Average: $" sum/count}'

# Product sales distribution
echo -e "\nTop 10 products by revenue:"
hdfs dfs -cat /user/training/datasets/sales_data.csv | \
  awk -F',' 'NR>1 {revenue[$3]+=$4*$5} END {for(p in revenue) print revenue[p], "Product_" p}' | \
  sort -nr | head -10
```

## Security and Quotas

### 14. Managing Storage Quotas

```bash
# Set directory quota (number of files/directories)
hdfs dfsadmin -setQuota 1000 /user/training/

# Set space quota (in bytes)
hdfs dfsadmin -setSpaceQuota 1G /user/training/datasets/

# Check quota usage
hdfs dfs -count -q /user/training/

# Clear quotas
hdfs dfsadmin -clrQuota /user/training/
hdfs dfsadmin -clrSpaceQuota /user/training/datasets/
```

### 15. Access Control Lists (ACLs)

```bash
# Enable ACLs (requires configuration)
# Add to hdfs-site.xml: dfs.namenode.acls.enabled = true

# Set ACL permissions
hdfs dfs -setfacl -m user:hadoop:rwx /user/training/datasets/

# Get ACL information
hdfs dfs -getfacl /user/training/datasets/

# Set default ACLs for new files
hdfs dfs -setfacl -m default:user:hadoop:rwx /user/training/datasets/

# Remove ACLs
hdfs dfs -setfacl -x user:hadoop /user/training/datasets/
```

## Best Practices and Tips

### 16. HDFS Best Practices

```bash
# 1. Optimal file sizes (avoid small files)
echo "Checking for small files (< 1MB):"
hdfs dfs -find /user/training/ -size -1048576 2>/dev/null | head -10

# 2. Use appropriate block sizes
echo -e "\nRecommended block sizes:"
echo "- Small files (< 100MB): Use default 128MB"
echo "- Large files (> 1GB): Consider 256MB or 512MB"
echo "- Very large files (> 10GB): Consider 1GB"

# 3. Monitor replication factor
echo -e "\nChecking replication factors:"
hdfs fsck /user/training/ -files | grep "repl=" | head -5

# 4. Regular cleanup
echo -e "\nCleaning up old files:"
# Find files older than 30 days (example)
find /tmp -name "*.tmp" -mtime +30 -type f

# 5. Use compression for large files
echo -e "\nCompression example:"
hdfs dfs -cat /user/training/datasets/sales_data.csv | gzip > /tmp/sales_compressed.csv.gz
hdfs dfs -put /tmp/sales_compressed.csv.gz /user/training/datasets/
echo "Original vs Compressed sizes:"
hdfs dfs -ls -l /user/training/datasets/sales_data.csv
hdfs dfs -ls -l /user/training/datasets/sales_compressed.csv.gz
```

## Troubleshooting Common Issues

### 17. Common Problems and Solutions

```bash
# Problem 1: Permission denied
echo "=== Troubleshooting Permission Issues ==="
hdfs dfs -ls -l /user/training/
echo "Solution: Check ownership and permissions"
echo "hdfs dfs -chown hadoop:hadoop /path/to/file"
echo "hdfs dfs -chmod 755 /path/to/file"

# Problem 2: Disk space issues
echo -e "\n=== Troubleshooting Disk Space ==="
hdfs dfs -df -h
echo "Solution: Clean up old files or increase storage"

# Problem 3: Block corruption
echo -e "\n=== Checking for Corruption ==="
hdfs fsck /user/training/ -files -blocks | grep -E "(CORRUPT|MISSING)" || echo "No corruption found"

# Problem 4: NameNode issues
echo -e "\n=== NameNode Health ==="
curl -s http://localhost:9870/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus | \
  python3 -c "import sys,json; data=json.load(sys.stdin); print('NameNode State:', data['beans'][0]['State'])" 2>/dev/null || \
  echo "NameNode web interface not accessible"
```

## Summary and Next Steps

You have learned:

✅ **Basic HDFS Operations**: File upload, download, navigation  
✅ **Advanced Features**: Permissions, replication, block management  
✅ **Performance Monitoring**: Health checks, optimization  
✅ **Data Analysis**: Processing files directly from HDFS  
✅ **Administration**: Quotas, security, troubleshooting  

### Next Steps

1. **Practice with Real Data**: Use your own datasets
2. **Integration**: Learn how Hive, Impala, and Spark use HDFS
3. **Advanced Topics**: Federation, snapshots, encryption
4. **Automation**: Create scripts for common operations

### Additional Resources

- **HDFS Commands Reference**: Use `hdfs dfs -help` for full command list
- **Web UI**: Monitor via http://localhost:9870
- **Logs**: Check `$HADOOP_HOME/logs/` for troubleshooting
- **Configuration**: Review `hdfs-site.xml` for tuning parameters

Continue with [Hive Tutorial](hive-tutorial.md) to learn data warehousing on HDFS!