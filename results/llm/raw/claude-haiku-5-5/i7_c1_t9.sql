SET NOCOUNT ON;

DECLARE @vals TABLE (v nvarchar(200) NOT NULL);
INSERT INTO @vals (v) VALUES
    (N'Subject_0000042'),
    (N'subject42@example.invalid'),
    (N'+1-555-0000042');

CREATE TABLE #results (
    object_name nvarchar(400) NOT NULL PRIMARY KEY,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @oid int, @pred nvarchar(max), @n bigint;
DECLARE @sql nvarchar(max);

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table, @oid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @n = 0;

    SELECT @pred = STRING_AGG(CAST(
            N'CHARINDEX(N''' + REPLACE(v.v, N'''', N'''''') + N''', CAST(' + QUOTENAME(c.name)
            + N' AS nvarchar(max))) > 0' AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    CROSS JOIN @vals AS v
    WHERE c.object_id = @oid
      AND c.system_type_id IN (35, 99, 167, 175, 231, 239);  -- text, ntext, varchar, char, nvarchar, nchar

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';
        EXEC sys.sp_executesql @sql, N'@cnt bigint OUTPUT', @cnt = @n OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (CAST(QUOTENAME(@schema) + N'.' + QUOTENAME(@table) AS nvarchar(400))
            .Replace(N'[', N'').Replace(N']', N''), @n);

    FETCH NEXT FROM tbl_cur INTO @schema, @table, @oid;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
