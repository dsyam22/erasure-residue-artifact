SET NOCOUNT ON;

DECLARE @customer_id INT = 42;
DECLARE @phone NVARCHAR(50) = '+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check current customer table (phone column dropped, so no phone data expected)
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', 0;

-- Check CDC change table for any captured phone data
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dbo_customer_CT' AND schema_id = SCHEMA_ID('cdc'))
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @customer_id
      AND phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', 0;
END

-- Check for any temporal history tables (none expected, but verify)
IF EXISTS (SELECT 1 FROM sys.tables WHERE temporal_type = 2 AND name = 'customer')
BEGIN
    DECLARE @history_table NVARCHAR(255);
    SELECT @history_table = QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name)
    FROM sys.tables
    WHERE temporal_type = 2 AND name = 'customer';

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'INSERT INTO #results (object_name, rows_found)
                 SELECT ''' + @history_table + ''', COUNT(*)
                 FROM ' + @history_table + '
                 WHERE customer_id = @customer_id
                   AND phone = @phone';
    EXEC sp_executesql @sql, N'@customer_id INT, @phone NVARCHAR(50)', @customer_id, @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'dbo.customer_history', 0;
END

-- Check for any other tables that might contain phone data (common downstream copies)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'customer_archive')
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'dbo.customer_archive', COUNT(*)
    FROM dbo.customer_archive
    WHERE customer_id = @customer_id
      AND phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'dbo.customer_archive', 0;
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'customer_backup')
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'dbo.customer_backup', COUNT(*)
    FROM dbo.customer_backup
    WHERE customer_id = @customer_id
      AND phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'dbo.customer_backup', 0;
END

-- Check any table with 'phone' column that is not the main customer table
DECLARE @table_name NVARCHAR(255);
DECLARE @schema_name NVARCHAR(128);
DECLARE @full_name NVARCHAR(255);
DECLARE @dynamic_sql NVARCHAR(MAX);

DECLARE table_cursor CURSOR FOR
SELECT s.name, t.name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.name = 'phone'
  AND NOT (s.name = 'dbo' AND t.name = 'customer')
  AND t.temporal_type = 0;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @full_name = QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name);
    SET @dynamic_sql = N'INSERT INTO #results (object_name, rows_found)
                         SELECT ''' + @full_name + ''', COUNT(*)
                         FROM ' + @full_name + '
                         WHERE customer_id = @customer_id
                           AND phone = @phone';
    EXEC sp_executesql @dynamic_sql, N'@customer_id INT, @phone NVARCHAR(50)', @customer_id, @phone;
    
    FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return final results
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
