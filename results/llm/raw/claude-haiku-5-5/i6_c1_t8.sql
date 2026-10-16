SET NOCOUNT ON;

DECLARE @p_formatted nvarchar(100) = N'%+1-555-0000042%';
DECLARE @p_digits    nvarchar(100) = N'%5550000042%';

DECLARE @results TABLE (
    object_name nvarchar(300) NOT NULL PRIMARY KEY,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @obj nvarchar(300),
        @where nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tbl;
FETCH NEXT FROM tbl INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @where = NULL;
    SET @cnt = 0;

    SELECT @where = STRING_AGG(CONVERT(nvarchar(max),
            N'CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE @p1 OR CAST('
            + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE @p2'), N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(@obj)
      AND c.system_type_id IN (167, 175, 231, 239, 35, 99, 241); -- varchar, char, nvarchar, nchar, text, ntext, xml

    IF @where IS NULL
    BEGIN
        INSERT INTO @results (object_name, rows_found)
        VALUES (@schema + N'.' + @table, 0);
    END
    ELSE
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + @obj + N' WHERE ' + @where + N';';
        EXEC sp_executesql @sql,
             N'@p1 nvarchar(100), @p2 nvarchar(100), @cnt bigint OUTPUT',
             @p1 = @p_formatted, @p2 = @p_digits, @cnt = @cnt OUTPUT;

        INSERT INTO @results (object_name, rows_found)
        VALUES (@schema + N'.' + @table, ISNULL(@cnt, 0));
    END

    FETCH NEXT FROM tbl INTO @schema, @table;
END

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
