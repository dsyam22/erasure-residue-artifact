SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(257),
    rows_found bigint
);

-- Check current table
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check temporal history table
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'dbo.customer_history',
    COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check for any CDC change tables (even though CDC is disabled, check if any exist)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name LIKE 'cdc.%')
BEGIN
    DECLARE @cdc_table nvarchar(257);
    DECLARE cdc_cursor CURSOR FOR
        SELECT QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name)
        FROM sys.tables
        WHERE name LIKE 'cdc.%'
          AND name LIKE '%customer%';

    OPEN cdc_cursor;
    FETCH NEXT FROM cdc_cursor INTO @cdc_table;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql nvarchar(max) = 
            N'INSERT INTO #results (object_name, rows_found) ' +
            N'SELECT @obj, COUNT(*) FROM ' + @cdc_table +
            N' WHERE customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph';

        EXEC sp_executesql @sql,
            N'@obj nvarchar(257), @cid int, @fn nvarchar(255), @em nvarchar(255), @ph nvarchar(50)',
            @obj = @cdc_table,
            @cid = @customer_id,
            @fn = @full_name,
            @em = @email,
            @ph = @phone;

        FETCH NEXT FROM cdc_cursor INTO @cdc_table;
    END;

    CLOSE cdc_cursor;
    DEALLOCATE cdc_cursor;
END;

-- Check for any other tables that might contain customer data (common naming patterns)
DECLARE @table_name nvarchar(257);
DECLARE table_cursor CURSOR FOR
    SELECT QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name)
    FROM sys.tables
    WHERE name IN ('customer_backup', 'customer_archive', 'customer_deleted', 'customer_log', 'customer_audit')
       OR name LIKE '%customer%copy%'
       OR name LIKE '%customer%backup%'
       OR name LIKE '%customer%archive%';

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @cols_exist int;
    
    -- Check if the table has the relevant columns
    SELECT @cols_exist = COUNT(*)
    FROM sys.columns
    WHERE object_id = OBJECT_ID(@table_name)
      AND name IN ('customer_id', 'full_name', 'email', 'phone');

    IF @cols_exist > 0
    BEGIN
        DECLARE @dynamic_sql nvarchar(max) = 
            N'INSERT INTO #results (object_name, rows_found) ' +
            N'SELECT @obj, COUNT(*) FROM ' + @table_name +
            N' WHERE customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph';

        EXEC sp_executesql @dynamic_sql,
            N'@obj nvarchar(257), @cid int, @fn nvarchar(255), @em nvarchar(255), @ph nvarchar(50)',
            @obj = @table_name,
            @cid = @customer_id,
            @fn = @full_name,
            @em = @email,
            @ph = @phone;
    END

    FETCH NEXT FROM table_cursor INTO @table_name;
END;

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return results
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
