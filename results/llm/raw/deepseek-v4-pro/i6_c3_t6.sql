SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#Results') IS NOT NULL
    DROP TABLE #Results;

CREATE TABLE #Results (
    object_name nvarchar(257),
    rows_found bigint
);

DECLARE @customer_id int = 42;
DECLARE @phone nvarchar(50) = '+1-555-0000042';

-- Check current table dbo.customer
INSERT INTO #Results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
  AND phone = @phone;

-- Check CDC capture instance table
IF EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'cdc' AND t.name = 'dbo_customer_CT'
)
BEGIN
    INSERT INTO #Results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @customer_id
      AND phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #Results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', 0;
END

-- Check any temporal history table (none defined for dbo.customer, but include for completeness)
IF EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'dbo_customer_history'
)
BEGIN
    INSERT INTO #Results (object_name, rows_found)
    SELECT 'dbo.dbo_customer_history', COUNT(*)
    FROM dbo.dbo_customer_history
    WHERE customer_id = @customer_id
      AND phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #Results (object_name, rows_found)
    SELECT 'dbo.dbo_customer_history', 0;
END

-- Check downstream copies: search all user tables for phone column and matching value
DECLARE @table_name nvarchar(257);
DECLARE @sql nvarchar(max);

DECLARE table_cursor CURSOR FOR
SELECT s.name + '.' + t.name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.name = 'phone'
  AND t.name NOT IN ('customer', 'dbo_customer_CT', 'dbo_customer_history');

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'INSERT INTO #Results (object_name, rows_found) SELECT @obj, COUNT(*) FROM ' + QUOTENAME(@table_name) + N' WHERE customer_id = @cid AND phone = @phone';
    EXEC sp_executesql @sql, N'@obj nvarchar(257), @cid int, @phone nvarchar(50)', @obj = @table_name, @cid = @customer_id, @phone = @phone;
    FETCH NEXT FROM table_cursor INTO @table_name;
END;

CLOSE table_cursor;
DEALLOCATE table_cursor;

SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;
