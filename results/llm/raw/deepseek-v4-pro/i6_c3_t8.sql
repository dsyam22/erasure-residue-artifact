DECLARE @customer_id INT = 42;
DECLARE @phone NVARCHAR(50) = '+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check current dbo.customer table (phone column should be dropped)
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', 0
WHERE NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID('dbo.customer')
      AND c.name = 'phone'
);

-- Check CDC change table
IF EXISTS (
    SELECT 1
    FROM sys.tables t
    WHERE t.name = 'dbo_customer_CT'
      AND SCHEMA_NAME(t.schema_id) = 'cdc'
)
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

-- Check temporal history tables (none expected, but verify)
IF EXISTS (
    SELECT 1
    FROM sys.tables t
    WHERE t.temporal_type = 1
      AND t.name LIKE '%customer%'
)
BEGIN
    DECLARE @history_table NVARCHAR(255);
    DECLARE @sql NVARCHAR(MAX);

    DECLARE hist_cursor CURSOR FOR
    SELECT QUOTENAME(SCHEMA_NAME(t.schema_id)) + '.' + QUOTENAME(t.name)
    FROM sys.tables t
    WHERE t.temporal_type = 1
      AND t.name LIKE '%customer%';

    OPEN hist_cursor;
    FETCH NEXT FROM hist_cursor INTO @history_table;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'INSERT INTO #results (object_name, rows_found) SELECT @hist, COUNT(*) FROM ' + @history_table + N' WHERE customer_id = @cid AND phone = @ph';
        EXEC sp_executesql @sql, N'@hist NVARCHAR(255), @cid INT, @ph NVARCHAR(50)', @hist=@history_table, @cid=@customer_id, @ph=@phone;
        FETCH NEXT FROM hist_cursor INTO @history_table;
    END

    CLOSE hist_cursor;
    DEALLOCATE hist_cursor;
END

-- Check for any other tables that might contain phone number for this customer
-- Search all user tables for columns named 'phone' and check for the specific value
DECLARE @table_name NVARCHAR(255);
DECLARE @column_name NVARCHAR(255);
DECLARE @full_name NVARCHAR(255);
DECLARE @sql2 NVARCHAR(MAX);

DECLARE table_cursor CURSOR FOR
SELECT 
    QUOTENAME(SCHEMA_NAME(t.schema_id)) + '.' + QUOTENAME(t.name),
    QUOTENAME(c.name)
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.name = 'phone'
  AND t.name NOT IN ('customer', 'dbo_customer_CT')
  AND t.temporal_type = 0;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @table_name, @column_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql2 = N'INSERT INTO #results (object_name, rows_found) SELECT @tbl, COUNT(*) FROM ' + @table_name + N' WHERE customer_id = @cid AND ' + @column_name + N' = @ph';
    EXEC sp_executesql @sql2, N'@tbl NVARCHAR(255), @cid INT, @ph NVARCHAR(50)', @tbl=@table_name, @cid=@customer_id, @ph=@phone;
    FETCH NEXT FROM table_cursor INTO @table_name, @column_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return results
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
