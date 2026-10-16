-- SCRIPT
SET NOCOUNT ON;

CREATE TABLE #results (
    object_name sysname NOT NULL,
    rows_found  int     NOT NULL
);

DECLARE @schema sysname, @table sysname, @cond nvarchar(max), @sql nvarchar(max), @n int;

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tcur;
FETCH NEXT FROM tcur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cond = NULL;
    SET @n = 0;

    -- Build a condition over all character columns: strip '-' and '+' and test for the digits of the phone number
    SELECT @cond = STRING_AGG(CAST(
        'REPLACE(REPLACE(' + QUOTENAME(c.name) + ',''-'',''''),''+'','''') LIKE ''%15550000042%''' AS nvarchar(max)), ' OR ')
    FROM sys.columns c
    JOIN sys.types ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND ty.name IN ('varchar', 'nvarchar', 'char', 'nchar');

    SET @sql = N'SELECT @n = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
             + N' WHERE ' + ISNULL(@cond, N'1 = 0') + N';';

    EXEC sp_executesql @sql, N'@n int OUTPUT', @n OUTPUT;

    INSERT INTO #results (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @n);

    FETCH NEXT FROM tcur INTO @schema, @table;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
