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

-- Check temporal history table (if exists)
IF EXISTS (
    SELECT 1 
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = N'dbo' AND t.name = N'customer_history'
)
BEGIN
    DECLARE @sql nvarchar(max) = N'
        INSERT INTO #results (object_name, rows_found)
        SELECT N''dbo.customer_history'', COUNT(*)
        FROM dbo.customer_history
        WHERE customer_id = @customer_id
           OR full_name = @full_name
           OR email = @email
           OR phone = @phone';
    EXEC sp_executesql @sql, N'@customer_id int, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(255)',
                       @customer_id, @full_name, @email, @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer_history', 0;
END

-- Check CDC change tables (if CDC enabled on database and table)
IF EXISTS (
    SELECT 1 
    FROM sys.change_tracking_tables ctt
    JOIN sys.tables t ON ctt.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = N'dbo' AND t.name = N'customer'
)
BEGIN
    DECLARE @cdc_schema nvarchar(255) = 'cdc';
    DECLARE @cdc_table nvarchar(255);
    SELECT @cdc_table = ct.name
    FROM sys.change_tracking_tables ctt
    JOIN sys.tables t ON ctt.object_id = t.object_id
    JOIN sys.tables ct ON ctt.change_tracking_object_id = ct.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = N'dbo' AND t.name = N'customer';
    
    IF @cdc_table IS NOT NULL
    BEGIN
        DECLARE @cdc_full_name nvarchar(512) = QUOTENAME(@cdc_schema) + N'.' + QUOTENAME(@cdc_table);
        DECLARE @cdc_sql nvarchar(max) = N'
            INSERT INTO #results (object_name, rows_found)
            SELECT @cdc_full_name, COUNT(*)
            FROM ' + @cdc_full_name + N'
            WHERE customer_id = @customer_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone';
        EXEC sp_executesql @cdc_sql, N'@cdc_full_name nvarchar(512), @customer_id int, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(255)',
                           @cdc_full_name, @customer_id, @full_name, @email, @phone;
    END
    ELSE
    BEGIN
        INSERT INTO #results (object_name, rows_found)
        SELECT N'cdc.dbo_customer_CT', 0;
    END
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', 0;
END

-- Check for any other tables that might contain customer data (common pattern: audit tables, backups, etc.)
-- We'll check any table with columns named like customer_id, full_name, email, phone that might hold copies
DECLARE @table_cursor CURSOR;
DECLARE @schema_name nvarchar(255);
DECLARE @table_name nvarchar(255);
DECLARE @full_table_name nvarchar(512);

SET @table_cursor = CURSOR FOR
SELECT s.name, t.name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.name NOT IN (N'customer', N'customer_history')
  AND EXISTS (
      SELECT 1 FROM sys.columns c 
      WHERE c.object_id = t.object_id 
      AND c.name IN (N'customer_id', N'full_name', N'email', N'phone')
  );

OPEN @table_cursor;
FETCH NEXT FROM @table_cursor INTO @schema_name, @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @full_table_name = QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name);
    
    DECLARE @check_sql nvarchar(max) = N'
        DECLARE @cnt int = 0;
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@full_table_name) AND name = N''customer_id'')
            AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@full_table_name) AND name IN (N''full_name'', N''email'', N''phone''))
        BEGIN
            SELECT @cnt = COUNT(*) FROM ' + @full_table_name + N'
            WHERE customer_id = @customer_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone;
        END
        INSERT INTO #results (object_name, rows_found)
        SELECT @full_table_name, @cnt;';
    
    EXEC sp_executesql @check_sql, N'@full_table_name nvarchar(512), @customer_id int, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(255)',
                       @full_table_name, @customer_id, @full_name, @email, @phone;
    
    FETCH NEXT FROM @table_cursor INTO @schema_name, @table_name;
END

CLOSE @table_cursor;
DEALLOCATE @table_cursor;

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
