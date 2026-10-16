-- SCRIPT
SET NOCOUNT ON;

DECLARE @subject_phone nvarchar(100) = N'+1-555-0000042';
DECLARE @sql nvarchar(max) = N'';
DECLARE @object_name nvarchar(776);
DECLARE @column_name sysname;
DECLARE @schema_name sysname;
DECLARE @table_name sysname;

CREATE TABLE #results (object_name nvarchar(776), rows_found bigint);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name, t.name, c.name
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE c.system_type_id IN (
        SELECT system_type_id FROM sys.types
        WHERE name IN ('nvarchar','nchar','varchar','char','text','ntext')
      )
  AND c.is_computed = 0
  AND t.is_ms_shipped = 0;

OPEN cur;
FETCH NEXT FROM cur INTO @schema_name, @table_name, @column_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @object_name = QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name);
    SET @sql = N'INSERT INTO #results SELECT @obj, COUNT_BIG(*) FROM ' + @object_name
             + N' WHERE ' + QUOTENAME(@column_name) + N' LIKE N''%'' + @phone + N''%'';';

    EXEC sp_executesql @sql,
        N'@obj nvarchar(776), @phone nvarchar(100)',
        @obj = @object_name,
        @phone = @subject_phone;

    FETCH NEXT FROM cur INTO @schema_name, @table_name, @column_name;
END

CLOSE cur;
DEALLOCATE cur;

SELECT object_name, SUM(rows_found) AS rows_found
FROM #results
GROUP BY object_name
ORDER BY object_name;

DROP TABLE #results;
