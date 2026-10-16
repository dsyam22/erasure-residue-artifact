SET NOCOUNT ON;

DECLARE @v1 nvarchar(200) = N'Subject_0000042';
DECLARE @v2 nvarchar(200) = N'subject42@example.invalid';
DECLARE @v3 nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results
(
    object_name nvarchar(400) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @pred nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tbl;
FETCH NEXT FROM tbl INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @cnt = 0;

    -- Build predicate over all character columns of the current table
    SELECT @pred = STRING_AGG(
               N'((CHARINDEX(@v1, ' + QUOTENAME(c.name) + N') > 0) OR '
             + N'(CHARINDEX(@v2, ' + QUOTENAME(c.name) + N') > 0) OR '
             + N'(CHARINDEX(@v3, ' + QUOTENAME(c.name) + N') > 0))', N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND c.system_type_id IN (167, 231, 175, 239);  -- varchar, nvarchar, char, nchar

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @c = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';

        EXEC sys.sp_executesql
             @sql,
             N'@v1 nvarchar(200), @v2 nvarchar(200), @v3 nvarchar(200), @c bigint OUTPUT',
             @v1 = @v1, @v2 = @v2, @v3 = @v3, @c = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @cnt);

    FETCH NEXT FROM tbl INTO @schema, @table;
END

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
