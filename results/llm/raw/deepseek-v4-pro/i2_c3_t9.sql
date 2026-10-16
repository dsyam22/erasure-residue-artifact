SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(500) NOT NULL,
    rows_found int NOT NULL
);

-- Check current table
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check temporal history table
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'dbo.customer_history' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.customer_history
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check for CDC change tables (if any exist)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'customer_CT' AND is_tracked_by_cdc = 1)
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 
        N'cdc.dbo_customer_CT' AS object_name,
        COUNT(*) AS rows_found
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END

-- Check for any other user tables that might contain the data (common downstream copies)
-- Looking for tables that have columns matching customer_id, full_name, email, phone
DECLARE @sql nvarchar(max) = N'';
DECLARE @table_name nvarchar(500);
DECLARE @schema_name nvarchar(128);

DECLARE table_cursor CURSOR FOR
SELECT 
    s.name AS schema_name,
    t.name AS table_name
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.name NOT IN ('customer', 'customer_history')
  AND EXISTS (
      SELECT 1 FROM sys.columns c 
      WHERE c.object_id = t.object_id 
        AND c.name IN ('customer_id', 'full_name', 'email', 'phone')
  );

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'INSERT INTO #results (object_name, rows_found) SELECT @obj_name, COUNT(*) FROM ' + 
               QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name) + 
               N' WHERE 1=0';
    
    -- Build dynamic WHERE clause based on available columns
    DECLARE @where_clause nvarchar(max) = N'';
    
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)) AND name = 'customer_id')
        SET @where_clause = @where_clause + N' OR customer_id = @customer_id';
    
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)) AND name = 'full_name')
        SET @where_clause = @where_clause + N' OR full_name = @full_name';
    
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)) AND name = 'email')
        SET @where_clause = @where_clause + N' OR email = @email';
    
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)) AND name = 'phone')
        SET @where_clause = @where_clause + N' OR phone = @phone';
    
    IF LEN(@where_clause) > 0
    BEGIN
        SET @where_clause = SUBSTRING(@where_clause, 4, LEN(@where_clause)); -- Remove leading ' OR '
        SET @sql = N'INSERT INTO #results (object_name, rows_found) SELECT @obj_name, COUNT(*) FROM ' + 
                   QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name) + 
                   N' WHERE ' + @where_clause;
        
        EXEC sp_executesql @sql, 
             N'@obj_name nvarchar(500), @customer_id int, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(255)',
             @obj_name = @schema_name + N'.' + @table_name,
             @customer_id = @customer_id,
             @full_name = @full_name,
             @email = @email,
             @phone = @phone;
    END
    
    FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return final results
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
