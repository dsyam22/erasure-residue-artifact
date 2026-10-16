SET NOCOUNT ON;

CREATE TABLE #results
(
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @schema sysname, @table sysname, @obj nvarchar(300), @pred nvarchar(max),
        @sql nvarchar(max), @cnt bigint;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj  = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @pred = NULL;
    SET @cnt  = 0;

    SELECT @pred = STRING_AGG(
               CONVERT(nvarchar(max),
                   QUOTENAME(col.name) + N' IN (N''Subject_0000042'', N''subject42@example.invalid'', N''+1-555-0000042'')'),
               N' OR ')
    FROM sys.columns AS col
    JOIN sys.types AS ty ON ty.user_type_id = col.user_type_id
    WHERE col.object_id = OBJECT_ID(@obj)
      AND ty.name IN (N'nvarchar', N'varchar', N'nchar', N'char');

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n = COUNT_BIG(*) FROM ' + @obj + N' WHERE ' + @pred + N';';
        EXEC sys.sp_executesql @sql, N'@n bigint OUTPUT', @n = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @cnt);

    FETCH NEXT FROM cur INTO @schema, @table;
END

CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
