SET NOCOUNT ON;

-- Subject's original personal data (LIKE patterns; '_' escaped as '\_')
DECLARE @p1 nvarchar(200) = N'%Subject\_0000042%',
        @p2 nvarchar(200) = N'%subject42@example.invalid%',
        @p3 nvarchar(200) = N'%+1-555-0000042%';

CREATE TABLE #results (
    object_name sysname NOT NULL PRIMARY KEY,
    rows_found  bigint  NOT NULL
);

DECLARE @schema sysname, @table sysname, @pred nvarchar(max), @sql nvarchar(max), @cnt bigint;

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
    SET @pred = NULL;
    SET @cnt  = 0;

    -- Build predicate across all character-type columns of this table
    SELECT @pred = STRING_AGG(
               N'(CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE @p1 ESCAPE ''\'''
             + N' OR CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE @p2 ESCAPE ''\'''
             + N' OR CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE @p3 ESCAPE ''\'')',
               N' OR ')
    FROM sys.columns AS c
    JOIN sys.types   AS ty ON ty.user_type_id = c.user_type_id
    JOIN sys.tables  AS t  ON t.object_id = c.object_id
    JOIN sys.schemas AS s  ON s.schema_id = t.schema_id
    WHERE s.name = @schema
      AND t.name = @table
      AND ty.name IN (N'char', N'nchar', N'varchar', N'nvarchar', N'text', N'ntext');

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT_BIG(*) FROM '
                 + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';

        EXEC sp_executesql
             @sql,
             N'@p1 nvarchar(200), @p2 nvarchar(200), @p3 nvarchar(200), @cnt bigint OUTPUT',
             @p1 = @p1, @p2 = @p2, @p3 = @p3, @cnt = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (CONVERT(sysname, @schema + N'.' + @table), ISNULL(@cnt, 0));

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
