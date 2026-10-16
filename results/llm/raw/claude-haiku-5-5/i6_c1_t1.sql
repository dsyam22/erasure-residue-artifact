SET NOCOUNT ON;

DECLARE @needle nvarchar(20) = N'5550000042';   -- phone digits with '+', '-', spaces removed

CREATE TABLE #results (
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @schema sysname, @table sysname, @oid int;
DECLARE @where nvarchar(max), @sql nvarchar(max);

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;

OPEN tbl;
FETCH NEXT FROM tbl INTO @schema, @table, @oid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @where = NULL;

    SELECT @where = STRING_AGG(CAST(
            N'REPLACE(REPLACE(REPLACE(CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)),N''-'',N''''),N'' '',N''''),N''+'',N'''') LIKE N''%'
            + @needle + N'%''' AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = @oid
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar');

    SET @sql = N'INSERT INTO #results (object_name, rows_found) SELECT N'''
             + REPLACE(QUOTENAME(@schema) + N'.' + QUOTENAME(@table), N'''', N'''''')
             + N''', COUNT_BIG(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
             + CASE WHEN @where IS NULL
                    THEN N' WHERE 1 = 0;'
                    ELSE N' WHERE ' + @where + N';'
               END;

    EXEC sys.sp_executesql @sql;

    FETCH NEXT FROM tbl INTO @schema, @table, @oid;
END;

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
