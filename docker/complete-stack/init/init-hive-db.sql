-- Initialize Hive Metastore Database
-- This script creates the necessary database and user for Hive Metastore

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS hive_metastore;

-- Create hive user and grant permissions
CREATE USER IF NOT EXISTS 'hive'@'%' IDENTIFIED BY 'hivepassword';
GRANT ALL PRIVILEGES ON hive_metastore.* TO 'hive'@'%';

-- Create local access user
CREATE USER IF NOT EXISTS 'hive'@'localhost' IDENTIFIED BY 'hivepassword';
GRANT ALL PRIVILEGES ON hive_metastore.* TO 'hive'@'localhost';

-- Flush privileges
FLUSH PRIVILEGES;

-- Display created users
SELECT User, Host FROM mysql.user WHERE User = 'hive';