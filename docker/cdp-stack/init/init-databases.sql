-- Initialize databases for CDP services
-- This script creates multiple databases needed for CDP components

-- Main CDP database
CREATE DATABASE IF NOT EXISTS cdp;

-- Cloudera Manager database
CREATE DATABASE IF NOT EXISTS scm;
CREATE USER IF NOT EXISTS 'scm'@'%' IDENTIFIED BY 'scm_password';
GRANT ALL PRIVILEGES ON scm.* TO 'scm'@'%';

-- Hive Metastore database
CREATE DATABASE IF NOT EXISTS hive_metastore;
CREATE USER IF NOT EXISTS 'hive'@'%' IDENTIFIED BY 'hive_password';
GRANT ALL PRIVILEGES ON hive_metastore.* TO 'hive'@'%';

-- Ranger database (for future security features)
CREATE DATABASE IF NOT EXISTS ranger;
CREATE USER IF NOT EXISTS 'ranger'@'%' IDENTIFIED BY 'ranger_password';
GRANT ALL PRIVILEGES ON ranger.* TO 'ranger'@'%';

-- Atlas database (for data governance)
CREATE DATABASE IF NOT EXISTS atlas;
CREATE USER IF NOT EXISTS 'atlas'@'%' IDENTIFIED BY 'atlas_password';
GRANT ALL PRIVILEGES ON atlas.* TO 'atlas'@'%';

-- Oozie database (for workflow management)
CREATE DATABASE IF NOT EXISTS oozie;
CREATE USER IF NOT EXISTS 'oozie'@'%' IDENTIFIED BY 'oozie_password';
GRANT ALL PRIVILEGES ON oozie.* TO 'oozie'@'%';

-- Hue database (for web interface)
CREATE DATABASE IF NOT EXISTS hue;
CREATE USER IF NOT EXISTS 'hue'@'%' IDENTIFIED BY 'hue_password';
GRANT ALL PRIVILEGES ON hue.* TO 'hue'@'%';

-- Flush privileges
FLUSH PRIVILEGES;

-- Display created databases and users
SELECT 'Databases created:' as status;
SHOW DATABASES;

SELECT 'Users created:' as status;
SELECT User, Host FROM mysql.user WHERE User IN ('scm', 'hive', 'ranger', 'atlas', 'oozie', 'hue');