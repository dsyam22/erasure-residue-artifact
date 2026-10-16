SET NOCOUNT ON;

DECLARE @phone nvarchar(50) = N'+1-555-0000042';
DECLARE @pattern nvarchar(100) = N'%' + @phone + N'%';

DECLARE @results TABLE (
    object_name nvarchar(776) NOT NULL,
    rows_found bigint NOT NULL
);

DECLARE @object_id int,
        @schema_name sysname,
        @table_name sysname,
        @qualified_name nvarchar(776),
        @predicate nvarchar(max),
        @sql nvarchar(max),
        @rows bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id,
           s.name,
           t.name,
           QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
    FROM sys.tables AS t
    INNER JOIN sys.schemas AS s
        ON t.schema_id = s.schema_id
    WHERE t.is_ms_shipped = 0
      AND t.is_external = 0
    ORDER BY s.name, t.name;

OPEN tbl_cur;

FETCH NEXT FROM tbl_cur
    INTO @object_id, @schema_name, @table_name, @qualified_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @predicate = STRING_AGG(
        CONVERT(nvarchar(max),
            N'TRY_CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE @pattern'
        ),
        N' OR '
    ) WITHIN GROUP (ORDER BY c.column_id)
    FROM sys.columns AS c
    WHERE c.object_id = @object_id;

    IF @predicate IS NULL
        SET @predicate = N'1 = 0';

    SET @sql = N'SELECT @rows = COUNT_BIG(*) FROM ' + @qualified_name
             + N' WHERE ' + @predicate + N';';

    SET @rows = 0;

    EXEC sys.sp_executesql @sql,
         N'@pattern nvarchar(100), @rows bigint OUTPUT',
         @pattern = @pattern,
         @rows = @rows OUTPUT;

    INSERT INTO @results (object_name, rows_found)
    VALUES (@schema_name + N'.' + @table_name, ISNULL(@rows, 0));

    FETCH NEXT FROM tbl_cur
        INTO @object_id, @schema_name, @table_name, @qualified_name;
END;

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
