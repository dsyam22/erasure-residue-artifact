SET NOCOUNT ON;

DECLARE @p1 nvarchar(200) = N'%Subject[_]0000042%';           -- full_name
DECLARE @p2 nvarchar(200) = N'%subject42@example.invalid%';   -- email
DECLARE @p3 nvarchar(200) = N'%+1-555-0000042%';              -- phone

CREATE TABLE #res (
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @schema sysname, @table sysname, @pred nvarchar(max), @sql nvarchar(max), @n bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name,
           (SELECT STRING_AGG(
                       N'(' + QUOTENAME(c.name) + N' LIKE @p1 OR '
                            + QUOTENAME(c.name) + N' LIKE @p2 OR '
                            + QUOTENAME(c.name) + N' LIKE @p3)', N' OR ')
              FROM sys.columns AS c
              JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
             WHERE c.object_id = t.object_id
               AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar'))
      FROM sys.tables AS t
      JOIN sys.schemas AS s ON s.schema_id = t.schema_id
     WHERE t.is_ms_shipped = 0
     ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table, @pred;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @pred IS NULL
    BEGIN
        INSERT INTO #res (object_name, rows_found)
        VALUES (CONCAT(@schema, N'.', @table), 0);
    END
    ELSE
    BEGIN
        SET @n = 0;
        SET @sql = N'SELECT @n_out = COUNT(*) FROM '
                 + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';

        EXEC sys.sp_executesql
             @sql,
             N'@p1 nvarchar(200), @p2 nvarchar(200), @p3 nvarchar(200), @n_out bigint OUTPUT',
             @p1 = @p1, @p2 = @p2, @p3 = @p3, @n_out = @n OUTPUT;

        INSERT INTO #res (object_name, rows_found)
        VALUES (CONCAT(@schema, N'.', @table), ISNULL(@n, 0));
    END

    FETCH NEXT FROM tbl_cur INTO @schema, @table, @pred;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #res
ORDER BY object_name;

DROP TABLE #res;
