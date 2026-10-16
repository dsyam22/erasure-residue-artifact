SET NOCOUNT ON;

DECLARE @p_full  nvarchar(200) = N'Subject_0000042';
DECLARE @p_email nvarchar(200) = N'subject42@example.invalid';
DECLARE @p_phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @oid   int,
        @sch   sysname,
        @tbl   sysname,
        @cond  nvarchar(max),
        @sql   nvarchar(max),
        @cnt   bigint;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id, s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN cur;
FETCH NEXT FROM cur INTO @oid, @sch, @tbl;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cond = NULL;
    SET @cnt  = 0;

    -- Build a predicate over every character-type column of the table
    -- (varchar 167, char 175, nvarchar 231, nchar 239)
    SELECT @cond = STRING_AGG(CAST(
        N'CHARINDEX(@p1, ' + QUOTENAME(col.name) + N') > 0 OR '
      + N'CHARINDEX(@p2, ' + QUOTENAME(col.name) + N') > 0 OR '
      + N'CHARINDEX(@p3, ' + QUOTENAME(col.name) + N') > 0'
      AS nvarchar(max)), N' OR ')
    FROM sys.columns AS col
    WHERE col.object_id = @oid
      AND col.system_type_id IN (167, 175, 231, 239);

    SET @sql = N'SELECT @n = COUNT(*) FROM '
             + QUOTENAME(@sch) + N'.' + QUOTENAME(@tbl)
             + N' WHERE '
             + COALESCE(N'(' + @cond + N')', N'1 = 0')
             + N';';

    EXEC sp_executesql
         @sql,
         N'@p1 nvarchar(200), @p2 nvarchar(200), @p3 nvarchar(200), @n bigint OUTPUT',
         @p1 = @p_full,
         @p2 = @p_email,
         @p3 = @p_phone,
         @n  = @cnt OUTPUT;

    INSERT INTO #results (object_name, rows_found)
    VALUES (@sch + N'.' + @tbl, @cnt);

    FETCH NEXT FROM cur INTO @oid, @sch, @tbl;
END;

CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;
