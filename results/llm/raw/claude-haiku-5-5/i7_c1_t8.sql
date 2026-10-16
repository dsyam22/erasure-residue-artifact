SET NOCOUNT ON;

DECLARE @v1 nvarchar(200) = N'Subject_0000042';
DECLARE @v2 nvarchar(200) = N'subject42@example.invalid';
DECLARE @v3 nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #scan
(
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @pred nvarchar(max), @sql nvarchar(max), @n bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @n = 0;

    SELECT @pred = STRING_AGG(CAST(
            N'CHARINDEX(@v1, CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N')) > 0 OR '
          + N'CHARINDEX(@v2, CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N')) > 0 OR '
          + N'CHARINDEX(@v3, CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N')) > 0'
          AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.tables AS t ON t.object_id = c.object_id
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE s.name = @schema
      AND t.name = @table
      AND TYPE_NAME(c.system_type_id) IN (N'char', N'varchar', N'nchar', N'nvarchar', N'text', N'ntext');

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n_out = COUNT_BIG(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';

        EXEC sp_executesql
            @sql,
            N'@v1 nvarchar(200), @v2 nvarchar(200), @v3 nvarchar(200), @n_out bigint OUTPUT',
            @v1 = @v1, @v2 = @v2, @v3 = @v3, @n_out = @n OUTPUT;
    END

    INSERT INTO #scan (object_name, rows_found)
    VALUES (CONCAT(@schema, N'.', @table), ISNULL(@n, 0));

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #scan
ORDER BY object_name;

DROP TABLE #scan;
