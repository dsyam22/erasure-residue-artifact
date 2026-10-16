-- SCRIPT
SET NOCOUNT ON;

CREATE TABLE #checked (object_name sysname NOT NULL, rows_found int NOT NULL);

DECLARE @schema sysname, @table sysname, @obj sysname, @pred nvarchar(max), @sql nvarchar(max);

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj = @schema + N'.' + @table;
    SET @pred = NULL;

    SELECT @pred = STRING_AGG(CAST(
            N'(' + QUOTENAME(c.name) + N' LIKE N''%+1-555-0000042%'''
          + N' OR ' + QUOTENAME(c.name) + N' LIKE N''%555-0000042%'''
          + N' OR ' + QUOTENAME(c.name) + N' LIKE N''%5550000042%'')' AS nvarchar(max)), N' OR ')
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND c.system_type_id IN (167, 175, 231, 239);

    IF @pred IS NULL
        INSERT INTO #checked (object_name, rows_found) VALUES (@obj, 0);
    ELSE
    BEGIN
        SET @sql = N'INSERT INTO #checked (object_name, rows_found) '
                 + N'SELECT @o, COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';
        EXEC sp_executesql @sql, N'@o sysname', @o = @obj;
    END

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #checked
ORDER BY object_name;

DROP TABLE #checked;
