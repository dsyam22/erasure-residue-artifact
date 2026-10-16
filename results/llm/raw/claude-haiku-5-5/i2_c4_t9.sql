SET NOCOUNT ON;

CREATE TABLE #results (
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @oid   int,
        @name  sysname,
        @pred  nvarchar(max),
        @sql   nvarchar(max),
        @cnt   bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id, QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @oid, @name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;

    SELECT @pred = STRING_AGG(
               CAST(N'CHARINDEX(N''' + v.val + N''', CAST(' + QUOTENAME(c.name)
                    + N' AS nvarchar(max))) > 0' AS nvarchar(max)),
               N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    CROSS JOIN (VALUES (N'Subject_0000042'),
                       (N'subject42@example.invalid'),
                       (N'+1-555-0000042')) AS v(val)
    WHERE c.object_id = @oid
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'sysname',
                      N'text', N'ntext', N'xml');

    IF @pred IS NULL
        SET @pred = N'0 = 1';

    SET @sql = N'SELECT @cnt_out = COUNT_BIG(*) FROM ' + @name
             + N' WHERE ' + @pred + N';';

    SET @cnt = NULL;
    EXEC sp_executesql @sql, N'@cnt_out bigint OUTPUT', @cnt_out = @cnt OUTPUT;

    INSERT INTO #results (object_name, rows_found)
    VALUES (REPLACE(REPLACE(@name, N'[', N''), N']', N''), ISNULL(@cnt, 0));

    FETCH NEXT FROM tbl_cur INTO @oid, @name;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;
