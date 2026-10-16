SET NOCOUNT ON;

CREATE TABLE #results (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @sch     sysname,
        @tbl     sysname,
        @oid     int,
        @pred    nvarchar(max),
        @sql     nvarchar(max);

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @sch, @tbl, @oid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;

    -- Build a predicate: any character column containing the subject's original
    -- name, email or phone, OR an int customer_id column equal to 42.
    SELECT @pred = STRING_AGG(CAST(x.p AS nvarchar(max)), N' OR ')
    FROM (
        SELECT N'(' + QUOTENAME(c.name) + N' IS NOT NULL AND ('
             + N'CHARINDEX(N''Subject_0000042'', '        + QUOTENAME(c.name) + N') > 0 OR '
             + N'CHARINDEX(N''subject42@example.invalid'', ' + QUOTENAME(c.name) + N') > 0 OR '
             + N'CHARINDEX(N''+1-555-0000042'', '         + QUOTENAME(c.name) + N') > 0))' AS p
        FROM sys.columns AS c
        JOIN sys.types   AS ty ON ty.user_type_id = c.user_type_id
        WHERE c.object_id = @oid
          AND ty.name IN ('char', 'varchar', 'nchar', 'nvarchar')
        UNION ALL
        SELECT QUOTENAME(c.name) + N' = 42'
        FROM sys.columns AS c
        WHERE c.object_id = @oid
          AND c.name = N'customer_id'
          AND c.system_type_id = 56  -- int
    ) AS x;

    SET @sql = N'INSERT INTO #results (object_name, rows_found) SELECT N'''
             + REPLACE(@sch + N'.' + @tbl, N'''', N'''''')
             + N''', COUNT_BIG(*) FROM ' + QUOTENAME(@sch) + N'.' + QUOTENAME(@tbl)
             + N' WHERE ' + ISNULL(@pred, N'1 = 0') + N';';

    EXEC sys.sp_executesql @sql;

    FETCH NEXT FROM tbl_cur INTO @sch, @tbl, @oid;
END;

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
