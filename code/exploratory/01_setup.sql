-- 01_setup.sql
-- Creates the lab database, one table of synthetic personal data, and enables CDC.
-- All data is synthetic (example.invalid addresses); no real personal data is used.
SET NOCOUNT ON;
GO

IF DB_ID('erasure_lab') IS NULL
    CREATE DATABASE erasure_lab;
GO

USE erasure_lab;
GO

IF OBJECT_ID('dbo.customer') IS NULL
    CREATE TABLE dbo.customer (
        customer_id INT           NOT NULL PRIMARY KEY,
        full_name   NVARCHAR(100) NOT NULL,
        email       NVARCHAR(200) NOT NULL,
        phone       NVARCHAR(30)  NULL,
        created_at  DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
    );
GO

-- Enable CDC on the database (idempotent)
IF (SELECT is_cdc_enabled FROM sys.databases WHERE name = 'erasure_lab') = 0
    EXEC sys.sp_cdc_enable_db;
GO

-- Enable CDC on the table (idempotent)
IF NOT EXISTS (SELECT 1 FROM cdc.change_tables
               WHERE source_object_id = OBJECT_ID('dbo.customer'))
    EXEC sys.sp_cdc_enable_table
        @source_schema        = N'dbo',
        @source_name          = N'customer',
        @role_name            = NULL,
        @supports_net_changes = 1;
GO

-- Load 1,000 synthetic subjects AFTER CDC is on, so the inserts are captured
IF NOT EXISTS (SELECT 1 FROM dbo.customer)
BEGIN
    ;WITH n AS (
        SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
        FROM sys.all_objects a CROSS JOIN sys.all_objects b
    )
    INSERT dbo.customer (customer_id, full_name, email, phone)
    SELECT i,
           CONCAT('Subject_', RIGHT(CONCAT('000000', i), 6)),
           CONCAT('subject', i, '@example.invalid'),
           CONCAT('+1-555-', RIGHT(CONCAT('0000', i), 4))
    FROM n;
END
GO

PRINT '--- Environment check ---';
SELECT servicename, status_desc FROM sys.dm_server_services;
SELECT name, is_cdc_enabled FROM sys.databases WHERE name = 'erasure_lab';
SELECT capture_instance, create_date FROM cdc.change_tables;
SELECT COUNT(*) AS customer_rows FROM dbo.customer;

PRINT '--- CDC job configuration (retention is in minutes) ---';
EXEC sys.sp_cdc_help_jobs;
GO
