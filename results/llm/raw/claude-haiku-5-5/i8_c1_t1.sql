SET NOCOUNT ON;

DECLARE @n1 nvarchar(100) = N'Subject_0000042';
DECLARE @n2 nvarchar(100) = N'subject42@example.invalid';
DECLARE @n3 nvarchar(100) = N'+1-555-0000042';

CREATE TABLE #results
(
    object_name nvarchar(260) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @obj nvarchar(400),
        @where nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;

OPEN tbl;
FETCH NEXT FROM tbl INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj   = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @where = NULL;
    SET @cnt   = 0;

    SELECT @where = STRING_AGG(CAST(
            N'(CHARINDEX(@p1, ' + QUOTENAME(c.name) + N') > 0 OR '
          + N'CHARINDEX(@p2, ' + QUOTENAME(c.name) + N') > 0 OR '
          + N'CHARINDEX(@p3, ' + QUOTENAME(c.name) + N') > 0)' AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(@obj)
      AND ty.name IN (N'nvarchar', N'varchar', N'nchar', N'char');

    IF @where IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + @obj + N' WHERE ' + @where;
        EXEC sys.sp_executesql
             @sql,
             N'@p1 nvarchar(100), @p2 nvarchar(100), @p3 nvarchar(100), @cnt bigint OUTPUT',
             @p1 = @n1, @p2 = @n2, @p3 = @n3, @cnt = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @cnt);

    FETCH NEXT FROM tbl INTO @schema, @table;
END

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
