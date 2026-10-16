SET NOCOUNT ON;

DECLARE @results TABLE (object_name nvarchar(300) NOT NULL, rows_found bigint NOT NULL);
DECLARE @sch sysname, @tbl sysname, @cond nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @sch, @tbl;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cond = NULL;
    SET @cnt = 0;

    -- Build a row-level predicate: any character column contains any of the subject's original personal data
    SELECT @cond = STRING_AGG(CAST(
        '(CHARINDEX(N''Subject_0000042'', ' + QUOTENAME(c.name) + N') > 0'
      + ' OR CHARINDEX(N''subject42@example.invalid'', ' + QUOTENAME(c.name) + N') > 0'
      + ' OR CHARINDEX(N''+1-555-0000042'', ' + QUOTENAME(c.name) + N') > 0)'
        AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@sch) + N'.' + QUOTENAME(@tbl))
      AND ty.name IN (N'nvarchar', N'varchar', N'nchar', N'char');

    IF @cond IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n = COUNT_BIG(*) FROM ' + QUOTENAME(@sch) + N'.' + QUOTENAME(@tbl)
                 + N' WHERE ' + @cond + N';';
        EXEC sys.sp_executesql @sql, N'@n bigint OUTPUT', @n = @cnt OUTPUT;
    END

    INSERT INTO @results (object_name, rows_found)
    VALUES (CONCAT(@sch, N'.', @tbl), ISNULL(@cnt, 0));

    FETCH NEXT FROM tbl_cur INTO @sch, @tbl;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
