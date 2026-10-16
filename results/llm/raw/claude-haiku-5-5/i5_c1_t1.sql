SET NOCOUNT ON;

DECLARE @p1 nvarchar(200) = N'%Subject[_]0000042%',        -- full_name (underscore escaped)
        @p2 nvarchar(200) = N'%subject42@example.invalid%', -- email
        @p3 nvarchar(200) = N'%+1-555-0000042%';            -- phone

CREATE TABLE #r (
    object_name nvarchar(400) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @oid  int,
        @sch  sysname,
        @tbl  sysname,
        @pred nvarchar(max),
        @sql  nvarchar(max),
        @cnt  int;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id, s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @oid, @sch, @tbl;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @cnt  = 0;

    -- Build a predicate over all character-type (and xml) columns of this table
    SELECT @pred = STRING_AGG(
               N'(' + x.e + N' LIKE @p1 OR ' + x.e + N' LIKE @p2 OR ' + x.e + N' LIKE @p3)',
               N' OR ')
    FROM (
        SELECT CASE WHEN ty.name = 'xml'
                    THEN N'CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))'
                    ELSE QUOTENAME(c.name)
               END AS e
        FROM sys.columns AS c
        JOIN sys.types   AS ty ON ty.user_type_id = c.user_type_id
        WHERE c.object_id = @oid
          AND ty.name IN ('char', 'varchar', 'nchar', 'nvarchar', 'xml')
    ) AS x;

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT(*) FROM '
                 + QUOTENAME(@sch) + N'.' + QUOTENAME(@tbl)
                 + N' WHERE ' + @pred + N';';

        EXEC sys.sp_executesql
             @sql,
             N'@p1 nvarchar(200), @p2 nvarchar(200), @p3 nvarchar(200), @cnt int OUTPUT',
             @p1, @p2, @p3, @cnt OUTPUT;
    END

    INSERT INTO #r (object_name, rows_found)
    VALUES (@sch + N'.' + @tbl, @cnt);

    FETCH NEXT FROM tbl_cur INTO @oid, @sch, @tbl;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #r
ORDER BY object_name;
