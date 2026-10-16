SET NOCOUNT ON;

DECLARE @sql nvarchar(max) = N'';
DECLARE @schema sysname, @table sysname, @object_id int;
DECLARE @pred nvarchar(max);

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table, @object_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Predicate: any text column contains any of the subject's original personal data values
    SET @pred = NULL;
    SELECT @pred = STRING_AGG(
               CAST(N'CHARINDEX(N''' + v.tok + N''', ' + QUOTENAME(c.name) + N') > 0' AS nvarchar(max)),
               N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    CROSS JOIN (VALUES (N'Subject_0000042'),
                       (N'subject42@example.invalid'),
                       (N'+1-555-0000042')) AS v(tok)
    WHERE c.object_id = @object_id
      AND ty.name IN ('char', 'varchar', 'nchar', 'nvarchar', 'sysname');

    IF @pred IS NULL SET @pred = N'1 = 0';

    SET @sql = @sql
        + CASE WHEN @sql = N'' THEN N'' ELSE N' UNION ALL ' END
        + N'SELECT N''' + REPLACE(@schema, N'''', N'''''') + N'.' + REPLACE(@table, N'''', N'''''') + N''' AS object_name, '
        + N'COUNT(*) AS rows_found FROM '
        + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
        + N' WHERE ' + @pred;

    FETCH NEXT FROM tbl_cur INTO @schema, @table, @object_id;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

IF @sql = N''
    SELECT CAST(N'' AS nvarchar(256)) AS object_name, CAST(0 AS int) AS rows_found WHERE 1 = 0;
ELSE
BEGIN
    SET @sql = N'SELECT object_name, rows_found FROM (' + @sql + N') AS r ORDER BY object_name;';
    EXEC sys.sp_executesql @sql;
END
