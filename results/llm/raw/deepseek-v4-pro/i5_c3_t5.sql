SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

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
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer_history', COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check change data capture (CDC) change tables if CDC is enabled
IF EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID('dbo.customer'))
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', 0;
END

-- Check for any other tables that might contain copies of the data
-- We look for tables with columns matching the personal data fields
DECLARE @table_name nvarchar(255);
DECLARE @schema_name nvarchar(128);
DECLARE @sql nvarchar(max);

DECLARE table_cursor CURSOR FOR
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
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
    SET @sql = N'INSERT INTO #results (object_name, rows_found) SELECT @objname, COUNT(*) FROM ' + QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name) + N' WHERE 1=0';
    
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)) AND name = 'customer_id')
        SET @sql = @sql + N' OR customer_id = @custid';
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)) AND name = 'full_name')
        SET @sql = @sql + N' OR full_name = @fullname';
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)) AND name = 'email')
        SET @sql = @sql + N' OR email = @emailaddr';
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)) AND name = 'phone')
        SET @sql = @sql + N' OR phone = @phonenum';

    -- Remove the initial "1=0" if we added conditions
    IF @sql NOT LIKE '%WHERE 1=0%'
        SET @sql = REPLACE(@sql, N' WHERE 1=0', N' WHERE 1=1');

    DECLARE @full_obj_name nvarchar(255) = @schema_name + N'.' + @table_name;
    
    EXEC sp_executesql @sql, 
        N'@objname nvarchar(255), @custid int, @fullname nvarchar(255), @emailaddr nvarchar(255), @phonenum nvarchar(50)',
        @objname = @full_obj_name,
        @custid = @customer_id,
        @fullname = @full_name,
        @emailaddr = @email,
        @phonenum = @phone;

    FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
