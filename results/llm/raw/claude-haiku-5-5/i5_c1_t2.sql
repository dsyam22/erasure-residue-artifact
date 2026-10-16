SET NOCOUNT ON;

DECLARE @fn  nvarchar(4000) = N'Subject_0000042';
DECLARE @em  nvarchar(4000) = N'subject42@example.invalid';
DECLARE @ph  nvarchar(4000) = N'+1-555-0000042';
DECLARE @cid int            = 42;

CREATE TABLE #scan_results
(
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @schema sysname, @table sysname, @objname sysname, @obj nvarchar(517);
DECLARE @pred nvarchar(max), @sql nvarchar(max), @n bigint;

DECLARE table_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN table_cur;
FETCH NEXT FROM table_cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @objname = @schema + N'.' + @table;
    SET @obj     = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @pred    = NULL;
    SET @n       = 0;

    -- Build the match predicate from the table's columns.
    SELECT @pred = STRING_AGG(CAST(
            CASE
                WHEN ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar')
                    THEN N'(CHARINDEX(@fn, ' + QUOTENAME(c.name) + N') > 0 OR '
                       + N'CHARINDEX(@em, ' + QUOTENAME(c.name) + N') > 0 OR '
                       + N'CHARINDEX(@ph, ' + QUOTENAME(c.name) + N') > 0)'
                WHEN c.name = N'customer_id' AND ty.name IN (N'int', N'bigint', N'smallint', N'tinyint')
                    THEN QUOTENAME(c.name) + N' = @cid'
            END AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(@obj)
      AND (ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar')
           OR (c.name = N'customer_id' AND ty.name IN (N'int', N'bigint', N'smallint', N'tinyint')));

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n = COUNT_BIG(*) FROM ' + @obj + N' WHERE ' + @pred + N';';
        EXEC sys.sp_executesql
            @sql,
            N'@fn nvarchar(4000), @em nvarchar(4000), @ph nvarchar(4000), @cid int, @n bigint OUTPUT',
            @fn = @fn, @em = @em, @ph = @ph, @cid = @cid, @n = @n OUTPUT;
    END

    INSERT INTO #scan_results (object_name, rows_found)
    VALUES (@objname, ISNULL(@n, 0));

    FETCH NEXT FROM table_cur INTO @schema, @table;
END

CLOSE table_cur;
DEALLOCATE table_cur;

SELECT object_name, rows_found
FROM #scan_results
ORDER BY object_name;
