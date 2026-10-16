DECLARE @needle nvarchar(4000) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found int);

DECLARE @schema sysname, @table sysname, @column sysname, @sql nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name, t.name, c.name
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE c.system_type_id IN (167, 231, 175, 239, 35, 99)  -- char/varchar/nchar/nvarchar/text/ntext
  AND t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.ordinal;

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table, @column;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
             + N' WHERE ' + QUOTENAME(@column) + N' LIKE N''%'' + @p + N''%'';';

    DECLARE @cnt int = 0;
    EXEC sp_executesql @sql, N'@p nvarchar(4000), @cnt int OUTPUT', @p = @needle, @cnt = @cnt OUTPUT;

    IF @cnt > 0
    BEGIN
        IF EXISTS (SELECT 1 FROM @results WHERE object_name = @schema + N'.' + @table)
            UPDATE @results SET rows_found = rows_found + @cnt
            WHERE object_name = @schema + N'.' + @table;
        ELSE
            INSERT INTO @results (object_name, rows_found) VALUES (@schema + N'.' + @table, @cnt);
    END
    ELSE
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM @results WHERE object_name = @schema + N'.' + @table)
            INSERT INTO @results (object_name, rows_found) VALUES (@schema + N'.' + @table, 0);
    END

    FETCH NEXT FROM cur INTO @schema, @table, @column;
END

CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found FROM @results ORDER BY object_name;
