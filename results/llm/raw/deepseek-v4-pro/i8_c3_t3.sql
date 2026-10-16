SET NOCOUNT ON;

DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = N'Subject_0000042';
DECLARE @email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check CDC change tables (if any exist for dbo.customer)
IF EXISTS (SELECT 1 FROM sys.tables t
           JOIN sys.schemas s ON t.schema_id = s.schema_id
           WHERE s.name = 'cdc' AND t.name LIKE 'dbo_customer%')
BEGIN
    DECLARE @cdc_table NVARCHAR(255);
    DECLARE cdc_cursor CURSOR FOR
        SELECT s.name + N'.' + t.name
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = 'cdc' AND t.name LIKE 'dbo_customer%';
    
    OPEN cdc_cursor;
    FETCH NEXT FROM cdc_cursor INTO @cdc_table;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql NVARCHAR(MAX) = N'INSERT INTO #results (object_name, rows_found) SELECT @obj, COUNT(*) FROM ' + QUOTENAME(@cdc_table) + N' WHERE customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph';
        EXEC sp_executesql @sql,
            N'@obj NVARCHAR(255), @cid INT, @fn NVARCHAR(255), @em NVARCHAR(255), @ph NVARCHAR(255)',
            @obj = @cdc_table, @cid = @customer_id, @fn = @full_name, @em = @email, @ph = @phone;
        
        FETCH NEXT FROM cdc_cursor INTO @cdc_table;
    END
    
    CLOSE cdc_cursor;
    DEALLOCATE cdc_cursor;
END
ELSE
BEGIN
    -- No CDC tables, insert zero row
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', 0
    WHERE NOT EXISTS (SELECT 1 FROM #results WHERE object_name = N'cdc.dbo_customer_CT');
END

-- Check temporal history tables (if dbo.customer is temporal)
IF EXISTS (SELECT 1 FROM sys.tables t
           JOIN sys.schemas s ON t.schema_id = s.schema_id
           WHERE t.name = 'customer' AND t.temporal_type = 2)
BEGIN
    DECLARE @history_table NVARCHAR(255);
    SELECT @history_table = s.name + N'.' + t.name
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'customer' AND t.temporal_type = 2;
    
    DECLARE @sql_hist NVARCHAR(MAX) = N'INSERT INTO #results (object_name, rows_found) SELECT @obj, COUNT(*) FROM ' + QUOTENAME(@history_table) + N' WHERE customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph';
    EXEC sp_executesql @sql_hist,
        N'@obj NVARCHAR(255), @cid INT, @fn NVARCHAR(255), @em NVARCHAR(255), @ph NVARCHAR(255)',
        @obj = @history_table, @cid = @customer_id, @fn = @full_name, @em = @email, @ph = @phone;
END
ELSE
BEGIN
    -- No temporal history, insert zero row
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer_history', 0
    WHERE NOT EXISTS (SELECT 1 FROM #results WHERE object_name = N'dbo.customer_history');
END

-- Final select
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
