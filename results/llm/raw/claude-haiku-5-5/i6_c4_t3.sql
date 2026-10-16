SET NOCOUNT ON;

DECLARE @p1 nvarchar(100) = N'%+1-555-0000042%';
DECLARE @p2 nvarchar(100) = N'%15550000042%';

CREATE TABLE #results (
    object_name nvarchar(400) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @oid    int,
        @schema sysname,
        @table  sysname,
        @where  nvarchar(max),
        @sql    nvarchar(max),
        @n      bigint,
        @name   nvarchar(400);

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id, s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @oid, @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @where = NULL;
    SET @n = 0;

    SELECT @where = STRING_AGG(
               CAST(N'(' + QUOTENAME(c.name) + N' LIKE @p1 OR ' + QUOTENAME(c.name) + N' LIKE @p2)' AS nvarchar(max)),
               N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = @oid
      AND TYPE_NAME(c.user_type_id) IN ('char', 'varchar', 'nchar', 'nvarchar');

    SET @name = CAST(QUOTENAME(@schema) + N'.' + QUOTENAME(@table) AS nvarchar(400));

    IF @where IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n_out = COUNT(*) FROM ' + @name + N' WHERE ' + @where + N';';
        EXEC sp_executesql
             @sql,
             N'@p1 nvarchar(100), @p2 nvarchar(100), @n_out bigint OUTPUT',
             @p1 = @p1, @p2 = @p2, @n_out = @n OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@name, ISNULL(@n, 0));

    FETCH NEXT FROM tbl_cur INTO @oid, @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;
