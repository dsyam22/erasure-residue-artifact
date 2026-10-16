-- SCRIPT
SET NOCOUNT ON;

DECLARE @subject_phone nvarchar(400) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found int);

DECLARE @schema sysname, @table sysname, @column sysname, @sql nvarchar(max);

DECLARE col_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS c
JOIN INFORMATION_SCHEMA.TABLES t
  ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME
WHERE t.TABLE_TYPE = 'BASE TABLE'
  AND c.DATA_TYPE IN ('char','varchar','nchar','nvarchar','text','ntext','sysname');

OPEN col_cursor;
FETCH NEXT FROM col_cursor INTO @schema, @table, @column;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'INSERT INTO #results (object_name, rows_found) ' +
               N'SELECT @obj, COUNT_BIG(*) FROM ' +
               QUOTENAME(@schema) + N'.' + QUOTENAME(@table) +
               N' WHERE ' + QUOTENAME(@column) + N' LIKE @pat;';

    EXEC sp_executesql @sql,
        N'@obj sysname, @pat nvarchar(400)',
        @obj = @schema + N'.' + @table,
        @pat = N'%' + @subject_phone + N'%';

    FETCH NEXT FROM col_cursor INTO @schema, @table, @column;
END

CLOSE col_cursor;
DEALLOCATE col_cursor;

SELECT object_name, SUM(rows_found) AS rows_found
FROM #results
GROUP BY object_name
ORDER BY object_name;

DROP TABLE #results;
