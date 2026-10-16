SET NOCOUNT ON;

DECLARE @phone nvarchar(50) = N'+1-555-0000042';
DECLARE @pattern nvarchar(60) = N'%' + @phone + N'%';

CREATE TABLE #r (object_name nvarchar(400) NOT NULL, rows_found bigint NOT NULL);

DECLARE @schema sysname, @table sysname, @where nvarchar(max), @sql nvarchar(max), @n bigint;

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;

OPEN tcur;
FETCH NEXT FROM tcur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @where = NULL;
    SET @n = 0;

    -- Character columns only (varchar, nvarchar, char, nchar)
    SELECT @where = STRING_AGG(CAST(QUOTENAME(c.name) + N' LIKE @p' AS nvarchar(max)), N' OR ')
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND c.system_type_id IN (167, 231, 175, 239);

    IF @where IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @where + N';';
        EXEC sp_executesql @sql,
             N'@p nvarchar(60), @n bigint OUTPUT',
             @p = @pattern, @n = @n OUTPUT;
    END

    INSERT INTO #r (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @n);

    FETCH NEXT FROM tcur INTO @schema, @table;
END

CLOSE tcur;
DEALLOCATE tcur;

-- Stored module definitions (views, procedures, functions, triggers) containing the phone value
INSERT INTO #r (object_name, rows_found)
SELECT N'sys.sql_modules (object definitions)', COUNT(*)
FROM sys.sql_modules
WHERE definition LIKE @pattern;

SELECT object_name, rows_found
FROM #r
ORDER BY object_name;

DROP TABLE #r;
