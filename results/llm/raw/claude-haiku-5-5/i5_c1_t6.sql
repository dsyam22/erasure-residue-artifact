SET NOCOUNT ON;

DECLARE @p1 nvarchar(200) = N'%Subject!_0000042%';            -- full_name 'Subject_0000042' (LIKE-escaped with '!')
DECLARE @p2 nvarchar(200) = N'%subject42@example.invalid%';   -- email
DECLARE @p3 nvarchar(200) = N'%+1-555-0000042%';              -- phone

DECLARE @results TABLE (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @obj nvarchar(300);
DECLARE @where nvarchar(max), @sql nvarchar(max), @cnt bigint;

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
    SET @obj = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @where = NULL;
    SET @cnt = 0;

    -- Build predicate across all character-type columns of this table
    SELECT @where = STRING_AGG(CAST(
            N'(' + QUOTENAME(c.name) + N' LIKE @p1 ESCAPE ''!'''
          + N' OR ' + QUOTENAME(c.name) + N' LIKE @p2 ESCAPE ''!'''
          + N' OR ' + QUOTENAME(c.name) + N' LIKE @p3 ESCAPE ''!'')' AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(@obj)
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'text', N'ntext');

    IF @where IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @c = COUNT_BIG(*) FROM ' + @obj + N' WHERE ' + @where + N';';
        EXEC sp_executesql
            @sql,
            N'@p1 nvarchar(200), @p2 nvarchar(200), @p3 nvarchar(200), @c bigint OUTPUT',
            @p1 = @p1, @p2 = @p2, @p3 = @p3, @c = @cnt OUTPUT;
    END

    INSERT INTO @results (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @cnt);

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
