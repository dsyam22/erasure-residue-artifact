-- SCRIPT
SET NOCOUNT ON;

DECLARE @customer_id INT = 42;
DECLARE @phone_pattern NVARCHAR(100) = '+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check dbo.customer for phone number in any column
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
  AND (
      CAST(full_name AS NVARCHAR(MAX)) LIKE '%' + @phone_pattern + '%'
      OR CAST(email AS NVARCHAR(MAX)) LIKE '%' + @phone_pattern + '%'
  );

-- Search all user tables and columns for the phone number
DECLARE @table_schema NVARCHAR(128);
DECLARE @table_name NVARCHAR(128);
DECLARE @column_name NVARCHAR(128);
DECLARE @sql NVARCHAR(MAX);

DECLARE table_cursor CURSOR FOR
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE IN ('char', 'varchar', 'nvarchar', 'text', 'ntext', 'nchar')
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @table_schema, @table_name, @column_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'INSERT INTO #results (object_name, rows_found) ' +
               N'SELECT ''' + QUOTENAME(@table_schema) + N'.' + QUOTENAME(@table_name) + N''', ' +
               N'COUNT(*) FROM ' + QUOTENAME(@table_schema) + N'.' + QUOTENAME(@table_name) +
               N' WHERE ' + QUOTENAME(@column_name) + N' LIKE ''%' + @phone_pattern + N'%''';
    
    EXEC sp_executesql @sql;
    
    FETCH NEXT FROM table_cursor INTO @table_schema, @table_name, @column_name;
END;

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return final results
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
