-- SCRIPT
DECLARE @subject_customer_id INT = 42;
DECLARE @subject_phone NVARCHAR(20) = '+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check dbo.customer for phone number in any remaining columns
INSERT INTO #results (object_name, rows_found)
SELECT 
    'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE 
    customer_id = @subject_customer_id
    AND (
        CAST(full_name AS NVARCHAR(MAX)) LIKE '%' + @subject_phone + '%'
        OR CAST(email AS NVARCHAR(MAX)) LIKE '%' + @subject_phone + '%'
    );

-- Check all user tables for the phone number in any column
DECLARE @table_schema NVARCHAR(128);
DECLARE @table_name NVARCHAR(128);
DECLARE @column_name NVARCHAR(128);
DECLARE @sql NVARCHAR(MAX);

DECLARE table_cursor CURSOR FOR
SELECT 
    s.name AS schema_name,
    t.name AS table_name
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @table_schema, @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE column_cursor CURSOR FOR
    SELECT c.name
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(@table_schema + '.' + @table_name)
      AND c.system_type_id IN (167, 175, 231, 239, 35, 99, 34, 165, 173, 61, 189, 240, 241, 36, 40, 48, 52, 56, 58, 59, 60, 62, 98, 106, 108, 122, 127);
    
    OPEN column_cursor;
    FETCH NEXT FROM column_cursor INTO @column_name;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'
            INSERT INTO #results (object_name, rows_found)
            SELECT ''' + @table_schema + '.' + @table_name + ''', COUNT(*)
            FROM ' + QUOTENAME(@table_schema) + '.' + QUOTENAME(@table_name) + '
            WHERE CAST(' + QUOTENAME(@column_name) + ' AS NVARCHAR(MAX)) LIKE ''%' + @subject_phone + '%''';
        
        EXEC sp_executesql @sql;
        
        FETCH NEXT FROM column_cursor INTO @column_name;
    END
    
    CLOSE column_cursor;
    DEALLOCATE column_cursor;
    
    FETCH NEXT FROM table_cursor INTO @table_schema, @table_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Aggregate results by object_name
SELECT 
    object_name,
    SUM(rows_found) AS rows_found
FROM #results
GROUP BY object_name
ORDER BY object_name;

DROP TABLE #results;
