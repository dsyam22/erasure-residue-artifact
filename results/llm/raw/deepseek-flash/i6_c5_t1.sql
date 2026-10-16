-- SCRIPT
SET NOCOUNT ON;

DECLARE @needle nvarchar(200) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found bigint);

-- 1. Check dbo.customer (only full_name and email remain; phone column was dropped)
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE full_name LIKE '%' + @needle + '%'
   OR email     LIKE '%' + @needle + '%';

-- 2. Search every string column in every user table in the database
--    (excluding dbo.customer which was already checked above)
DECLARE @schema sysname, @table sysname, @column sysname, @sql nvarchar(max);

DECLARE col_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS c
JOIN INFORMATION_SCHEMA.TABLES t
  ON t.TABLE_SCHEMA = c.TABLE_SCHEMA
 AND t.TABLE_NAME   = c.TABLE_NAME
WHERE t.TABLE_TYPE = 'BASE TABLE'
  AND c.DATA_TYPE IN ('char','varchar','nchar','nvarchar','text','ntext','xml')
  AND NOT (c.TABLE_SCHEMA = 'dbo' AND c.TABLE_NAME = 'customer');

OPEN col_cursor;
FETCH NEXT FROM col_cursor INTO @schema, @table, @column;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
        INSERT INTO @results (object_name, rows_found)
        SELECT ' + QUOTENAME(@schema + '.' + @table, '''') + N',
               COUNT(*)
        FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
        WHERE CAST(' + QUOTENAME(@column) + N' AS nvarchar(max)) LIKE ''%'' + @needle + ''%'';';

    EXEC sp_executesql @sql, N'@needle nvarchar(200)', @needle;

    FETCH NEXT FROM col_cursor INTO @schema, @table, @column;
END

CLOSE col_cursor;
DEALLOCATE col_cursor;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
