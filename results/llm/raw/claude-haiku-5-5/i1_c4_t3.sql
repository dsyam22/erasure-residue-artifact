SET NOCOUNT ON;

DECLARE @result TABLE (object_name nvarchar(400) NOT NULL, rows_found bigint NOT NULL);
DECLARE @schema sysname, @table sysname, @obj nvarchar(400), @cond nvarchar(max), @sql nvarchar(max);

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
    SET @obj = @schema + N'.' + @table;

    -- Build a predicate: any character column containing one of the subject's original values
    SELECT @cond = STRING_AGG(
        CAST(N'(CHARINDEX(N''Subject_0000042'', ' + QUOTENAME(col.name) + N' COLLATE DATABASE_DEFAULT) > 0'
           + N' OR CHARINDEX(N''subject42@example.invalid'', ' + QUOTENAME(col.name) + N' COLLATE DATABASE_DEFAULT) > 0'
           + N' OR CHARINDEX(N''+1-555-0000042'', ' + QUOTENAME(col.name) + N' COLLATE DATABASE_DEFAULT) > 0)' AS nvarchar(max)),
        N' OR ')
    FROM sys.columns AS col
    JOIN sys.types AS ty ON ty.user_type_id = col.user_type_id
    WHERE col.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'sysname');

    IF @cond IS NULL
        SET @cond = N'1 = 0';

    SET @sql = N'SELECT COUNT_BIG(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
             + N' WHERE ' + @cond + N';';

    INSERT INTO @result (object_name, rows_found)
    EXEC sys.sp_executesql @sql;

    -- Ensure the object appears even if the insert above returned no row
    SET @cond = NULL;

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM @result
ORDER BY object_name;
