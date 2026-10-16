SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255) NOT NULL,
    rows_found int NOT NULL
);

-- Check current table
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check temporal history table
IF EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = N'customer_history' AND s.name = N'dbo'
)
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer_history', COUNT(*)
    FROM dbo.customer_history
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer_history', 0;
END

-- Check for CDC change tables (if CDC were enabled; database cdc_enabled=0, so none expected)
IF EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = N'customer_CT' AND s.name = N'cdc'
)
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.customer_CT', COUNT(*)
    FROM cdc.customer_CT
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.customer_CT', 0;
END

-- Check for any user tables that might contain a copy of the data (dynamic scan)
DECLARE @sql nvarchar(max) = N'';
DECLARE @table_name nvarchar(255);
DECLARE @schema_name nvarchar(255);

DECLARE table_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.is_ms_shipped = 0
      AND NOT (s.name = N'dbo' AND t.name IN (N'customer', N'customer_history'))
      AND NOT (s.name = N'cdc' AND t.name = N'customer_CT')
    ORDER BY s.name, t.name;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'IF EXISTS (SELECT 1 FROM sys.columns c JOIN sys.tables t ON c.object_id = t.object_id JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = @schema_name AND t.name = @table_name AND c.name IN (''customer_id'', ''full_name'', ''email'', ''phone'')) BEGIN INSERT INTO #results (object_name, rows_found) SELECT @full_object_name, COUNT(*) FROM ' + QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name) + N' WHERE ';
    
    DECLARE @conditions nvarchar(max) = N'';
    IF EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)) AND c.name = N'customer_id')
        SET @conditions = @conditions + N'customer_id = @customer_id OR ';
    IF EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)) AND c.name = N'full_name')
        SET @conditions = @conditions + N'full_name = @full_name OR ';
    IF EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)) AND c.name = N'email')
        SET @conditions = @conditions + N'email = @email OR ';
    IF EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)) AND c.name = N'phone')
        SET @conditions = @conditions + N'phone = @phone OR ';
    
    IF LEN(@conditions) > 0
    BEGIN
        SET @conditions = LEFT(@conditions, LEN(@conditions) - 3); -- remove trailing OR
        SET @sql = @sql + @conditions + N' END';
        
        EXEC sp_executesql @sql, 
            N'@schema_name nvarchar(255), @table_name nvarchar(255), @full_object_name nvarchar(255), @customer_id int, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(255)',
            @schema_name = @schema_name,
            @table_name = @table_name,
            @full_object_name = @schema_name + N'.' + @table_name,
            @customer_id = @customer_id,
            @full_name = @full_name,
            @email = @email,
            @phone = @phone;
    END
    
    FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
