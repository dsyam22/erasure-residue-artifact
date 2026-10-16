-- SCRIPT
SET NOCOUNT ON;

DECLARE @needle nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

-- 1) dbo.customer: phone column was dropped; verify no column remains and no residual match
IF EXISTS (SELECT 1 FROM sys.columns c
           JOIN sys.tables t ON t.object_id = c.object_id
           JOIN sys.schemas s ON s.schema_id = t.schema_id
           WHERE s.name = 'dbo' AND t.name = 'customer' AND c.name = 'phone')
BEGIN
    INSERT INTO #results
    EXEC sp_executesql N'SELECT ''dbo.customer'', COUNT(*) FROM dbo.customer WHERE phone = @p', N'@p nvarchar(200)', @p = @needle;
END
ELSE
BEGIN
    INSERT INTO #results VALUES ('dbo.customer', 0);
END

-- 2) Scan every text-based column in every user table for the phone number
DECLARE @schema sysname, @table sysname, @column sysname, @sql nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, c.name
    FROM sys.columns c
    JOIN sys.tables t ON t.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    JOIN sys.types ty ON ty.user_type_id = c.user_type_id
    WHERE t.is_ms_shipped = 0
      AND ty.name IN ('char','varchar','nchar','nvarchar','text','ntext')
      AND NOT (s.name = 'dbo' AND t.name = 'customer' AND c.name = 'phone');

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table, @column;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'INSERT INTO #results SELECT @obj, COUNT(*) FROM ' 
             + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
             + N' WHERE CAST(' + QUOTENAME(@column) + N' AS nvarchar(max)) LIKE N''%'' + @p + N''%'';';
    EXEC sp_executesql @sql,
        N'@obj sysname, @p nvarchar(200)',
        @obj = @schema + N'.' + @table + N'.' + @column,
        @p = @needle;
    FETCH NEXT FROM cur INTO @schema, @table, @column;
END

CLOSE cur;
DEALLOCATE cur;

-- Aggregate to one row per object (sum of matches across its columns)
SELECT object_name, SUM(rows_found) AS rows_found
FROM #results
GROUP BY object_name
ORDER BY object_name;

DROP TABLE #results;
