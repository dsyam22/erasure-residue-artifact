SET NOCOUNT ON;

DECLARE @u      nvarchar(max) = N'';
DECLARE @sql    nvarchar(max);
DECLARE @pred   nvarchar(max);
DECLARE @schema sysname;
DECLARE @table  sysname;
DECLARE @objid  int;

-- Search patterns (contains-match, case-insensitive under default collation).
-- '_' is escaped because it is a LIKE wildcard.
DECLARE @p1 nvarchar(200) = N'%Subject\_0000042%';
DECLARE @p2 nvarchar(200) = N'%subject42@example.invalid%';
DECLARE @p3 nvarchar(200) = N'%+1-555-0000042%';

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table, @objid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;

    -- Build the per-table WHERE predicate from its columns:
    -- character columns are searched for the three personal-data values;
    -- an int customer_id column is matched against 42.
    SELECT @pred = STRING_AGG(CAST(
        CASE WHEN ty.name IN ('char','varchar','nchar','nvarchar') THEN
            N'(' + QUOTENAME(c.name) + N' LIKE ' + QUOTENAME(@p1, '''') + N' ESCAPE ''\'' OR '
                 + QUOTENAME(c.name) + N' LIKE ' + QUOTENAME(@p2, '''') + N' OR '
                 + QUOTENAME(c.name) + N' LIKE ' + QUOTENAME(@p3, '''') + N')'
        ELSE
            QUOTENAME(c.name) + N' = 42'
        END AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = @objid
      AND (ty.name IN ('char','varchar','nchar','nvarchar')
           OR (c.name = N'customer_id' AND ty.name = 'int'));

    SET @u = @u
           + CASE WHEN @u = N'' THEN N'' ELSE N' UNION ALL ' END
           + N'SELECT ' + QUOTENAME(@schema + N'.' + @table, '''') + N' AS object_name, '
           + N'COUNT(*) AS rows_found FROM '
           + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
           + N' WHERE ' + ISNULL(@pred, N'1=0');

    FETCH NEXT FROM tbl_cur INTO @schema, @table, @objid;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SET @sql = N'SELECT object_name, rows_found FROM (' + @u + N') AS r ORDER BY object_name;';

EXEC sys.sp_executesql @sql;
