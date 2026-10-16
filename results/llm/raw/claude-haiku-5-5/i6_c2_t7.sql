SET NOCOUNT ON;

DECLARE @phone nvarchar(64) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @schema sysname, @table sysname, @where nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @where = NULL;
    SET @cnt = 0;

    -- Build a predicate over every character-type column of this table
    SELECT @where = STRING_AGG(
               CAST('CAST(' + QUOTENAME(c.name) + ' AS nvarchar(max)) LIKE N''%' + @phone + '%''' AS nvarchar(max)),
               ' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND ty.name IN ('char', 'varchar', 'nchar', 'nvarchar', 'text', 'ntext');

    IF @where IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @where + N';';
        EXEC sp_executesql @sql, N'@n bigint OUTPUT', @n = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @cnt);

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
