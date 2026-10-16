SET NOCOUNT ON;

DECLARE @name  nvarchar(100) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50)  = N'+1-555-0000042';

CREATE TABLE #scan_results
(
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @schema sysname, @table sysname, @oid int;
DECLARE @pred nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table, @oid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @cnt  = 0;

    SELECT @pred = STRING_AGG(CAST(
            N'CHARINDEX(@n, ' + QUOTENAME(c.name) + N') > 0 OR '
          + N'CHARINDEX(@e, ' + QUOTENAME(c.name) + N') > 0 OR '
          + N'CHARINDEX(@p, ' + QUOTENAME(c.name) + N') > 0'
          AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = @oid
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar');

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @c = COUNT(*) FROM '
                 + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';

        EXEC sys.sp_executesql
             @sql,
             N'@n nvarchar(100), @e nvarchar(200), @p nvarchar(50), @c bigint OUTPUT',
             @n = @name, @e = @email, @p = @phone, @c = @cnt OUTPUT;
    END

    INSERT INTO #scan_results (object_name, rows_found)
    VALUES (CONCAT(@schema, N'.', @table), ISNULL(@cnt, 0));

    FETCH NEXT FROM tbl_cur INTO @schema, @table, @oid;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #scan_results
ORDER BY object_name;

DROP TABLE #scan_results;
