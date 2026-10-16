SET NOCOUNT ON;

DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = N'Subject_0000042';
DECLARE @email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = N'+1-555-0000042';

IF OBJECT_ID('tempdb..#Results') IS NOT NULL
    DROP TABLE #Results;

CREATE TABLE #Results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check dbo.customer
INSERT INTO #Results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check reporting.customer_replica
INSERT INTO #Results (object_name, rows_found)
SELECT 
    N'reporting.customer_replica',
    COUNT(*)
FROM reporting.customer_replica
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check for CDC change tables (cdc_enabled=0, but still verify if any exist)
IF EXISTS (SELECT 1 FROM sys.objects WHERE name LIKE 'cdc.%' AND type = 'U')
BEGIN
    DECLARE @cdc_table_name NVARCHAR(255);
    DECLARE cdc_cursor CURSOR FOR
        SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.name LIKE 'dbo_customer%' OR t.name LIKE 'reporting_customer_replica%'
          AND t.is_ms_shipped = 0;

    OPEN cdc_cursor;
    FETCH NEXT FROM cdc_cursor INTO @cdc_table_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'INSERT INTO #Results (object_name, rows_found) SELECT @obj, COUNT(*) FROM ' + @cdc_table_name + 
                   N' WHERE (customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph)';
        EXEC sp_executesql @sql, 
            N'@obj NVARCHAR(255), @cid INT, @fn NVARCHAR(255), @em NVARCHAR(255), @ph NVARCHAR(255)',
            @obj = @cdc_table_name, @cid = @customer_id, @fn = @full_name, @em = @email, @ph = @phone;
        FETCH NEXT FROM cdc_cursor INTO @cdc_table_name;
    END;

    CLOSE cdc_cursor;
    DEALLOCATE cdc_cursor;
END

-- Check for temporal history tables (temporal_type=NON_TEMPORAL_TABLE, but still verify if any exist)
IF EXISTS (SELECT 1 FROM sys.tables WHERE temporal_type = 1)
BEGIN
    DECLARE @history_table_name NVARCHAR(255);
    DECLARE history_cursor CURSOR FOR
        SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.temporal_type = 1
          AND (t.name LIKE 'dbo_customer%' OR t.name LIKE 'reporting_customer_replica%');

    OPEN history_cursor;
    FETCH NEXT FROM history_cursor INTO @history_table_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql2 NVARCHAR(MAX);
        SET @sql2 = N'INSERT INTO #Results (object_name, rows_found) SELECT @obj, COUNT(*) FROM ' + @history_table_name + 
                    N' WHERE (customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph)';
        EXEC sp_executesql @sql2,
            N'@obj NVARCHAR(255), @cid INT, @fn NVARCHAR(255), @em NVARCHAR(255), @ph NVARCHAR(255)',
            @obj = @history_table_name, @cid = @customer_id, @fn = @full_name, @em = @email, @ph = @phone;
        FETCH NEXT FROM history_cursor INTO @history_table_name;
    END;

    CLOSE history_cursor;
    DEALLOCATE history_cursor;
END

-- Ensure at least one row per object checked (if no CDC/history tables, still return base tables)
SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;
