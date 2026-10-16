SET NOCOUNT ON;

DECLARE @p1 nvarchar(200) = N'Subject_0000042';
DECLARE @p2 nvarchar(200) = N'subject42@example.invalid';
DECLARE @p3 nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #scan
(
    object_name sysname NOT NULL PRIMARY KEY,
    rows_found  bigint  NOT NULL
);

DECLARE @oid int, @schema sysname, @tbl sysname, @pred nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id, s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;

OPEN tcur;
FETCH NEXT FROM tcur INTO @oid, @schema, @tbl;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;

    SELECT @pred = STRING_AGG(
        CAST(N'(CHARINDEX(@p1, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0 OR '
           + N'CHARINDEX(@p2, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0 OR '
           + N'CHARINDEX(@p3, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0)' AS nvarchar(max)),
        N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = @oid
      AND ty.name IN (N'varchar', N'nvarchar', N'char', N'nchar');

    SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@tbl)
             + N' WHERE ' + ISNULL(@pred, N'1 = 0') + N';';

    SET @cnt = 0;
    EXEC sys.sp_executesql
         @sql,
         N'@cnt bigint OUTPUT, @p1 nvarchar(200), @p2 nvarchar(200), @p3 nvarchar(200)',
         @cnt = @cnt OUTPUT,
         @p1 = @p1,
         @p2 = @p2,
         @p3 = @p3;

    INSERT INTO #scan (object_name, rows_found)
    VALUES (@schema + N'.' + @tbl, ISNULL(@cnt, 0));

    FETCH NEXT FROM tcur INTO @oid, @schema, @tbl;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #scan
ORDER BY object_name;
