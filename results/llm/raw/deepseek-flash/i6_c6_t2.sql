-- SCRIPT
SET NOCOUNT ON;

DECLARE @needle nvarchar(400) = N'+1-555-0000042';
DECLARE @needleNoPunct nvarchar(400) = N'15550000042';

CREATE TABLE #results (object_name sysname, rows_found int);

-- Check dbo.customer (phone column dropped) for residual phone data in remaining columns
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE full_name LIKE '%' + @needle + '%'
   OR email LIKE '%' + @needle + '%'
   OR full_name LIKE '%' + @needleNoPunct + '%'
   OR email LIKE '%' + @needleNoPunct + '%';

-- Scan every character column of every user table in the database
DECLARE @schema sysname, @table sysname, @column sysname;
DECLARE @sql nvarchar(max);

DECLARE col_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_SCHEMA NOT IN ('sys', 'INFORMATION_SCHEMA')
  AND c.DATA_TYPE IN ('char','varchar','nchar','nvarchar','text','ntext')
  AND NOT (c.TABLE_SCHEMA = 'dbo' AND c.TABLE_NAME = 'customer');

OPEN col_cursor;
FETCH NEXT FROM col_cursor INTO @schema, @table, @column;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
INSERT INTO #results (object_name, rows_found)
SELECT ' + QUOTENAME(@schema + '.' + @table, '''') + N', COUNT(*)
FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
WHERE ' + QUOTENAME(@column) + N' LIKE ''%'' + @needle + ''%''
   OR ' + QUOTENAME(@column) + N' LIKE ''%'' + @needleNoPunct + ''%'';';

    EXEC sp_executesql @sql,
        N'@needle nvarchar(400), @needleNoPunct nvarchar(400)',
        @needle = @needle, @needleNoPunct = @needleNoPunct;

    FETCH NEXT FROM col_cursor INTO @schema, @table, @column;
END

CLOSE col_cursor;
DEALLOCATE col_cursor;

SELECT object_name, SUM(rows_found) AS rows_found
FROM #results
GROUP BY object_name
ORDER BY object_name;

DROP TABLE #results;
