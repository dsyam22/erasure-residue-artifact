SET NOCOUNT ON;

-- Read-only check: searches every base table's character columns for the erased
-- personal data of subject 42. Only SELECT statements touch user tables; results
-- are collected in a temp table. customer_id (42) is a bare integer key and is not
-- matched, since it would produce false positives in unrelated numeric data.

DECLARE @p1 nvarchar(200) = N'%Subject\_0000042%';       -- full_name (escaped _)
DECLARE @p2 nvarchar(200) = N'%subject42@example.invalid%'; -- email
DECLARE @p3 nvarchar(200) = N'%+1-555-0000042%';          -- phone

CREATE TABLE #results (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @oid    int,
        @schema sysname,
        @table  sysname,
        @cond   nvarchar(max),
        @sql    nvarchar(max),
        @n      bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id, s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @oid, @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cond = NULL;
    SET @n = 0;

    SELECT @cond = STRING_AGG(
               CAST(
                   N'(' + QUOTENAME(c.name) + N' LIKE @p1 ESCAPE ''\'' OR '
                        + QUOTENAME(c.name) + N' LIKE @p2 ESCAPE ''\'' OR '
                        + QUOTENAME(c.name) + N' LIKE @p3 ESCAPE ''\'')'
               AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = @oid
      AND ty.name IN (N'char', N'nchar', N'varchar', N'nvarchar');

    IF @cond IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT_BIG(*) FROM '
                 + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @cond + N';';

        EXEC sys.sp_executesql
             @sql,
             N'@p1 nvarchar(200), @p2 nvarchar(200), @p3 nvarchar(200), @cnt bigint OUTPUT',
             @p1 = @p1, @p2 = @p2, @p3 = @p3, @cnt = @n OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (CAST(@schema + N'.' + @table AS nvarchar(300)), @n);

    FETCH NEXT FROM tbl_cur INTO @oid, @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
