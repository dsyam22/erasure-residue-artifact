SET NOCOUNT ON;

DECLARE @pat1 nvarchar(60) = N'%+1-555-0000042%';
DECLARE @pat2 nvarchar(60) = N'%15550000042%';

CREATE TABLE #results
(
    object_name nvarchar(300) NOT NULL PRIMARY KEY,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @obj nvarchar(300),
        @where nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tcur;
FETCH NEXT FROM tcur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @where = NULL;
    SET @cnt = 0;

    SELECT @where = STRING_AGG(
               CAST(N'(CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE @p1'
                  + N' OR CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE @p2)' AS nvarchar(max)),
               N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(@obj)
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'text', N'ntext');

    IF @where IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT_BIG(*) FROM ' + @obj
                 + N' WHERE ' + @where + N';';

        EXEC sp_executesql
            @sql,
            N'@p1 nvarchar(60), @p2 nvarchar(60), @cnt bigint OUTPUT',
            @p1 = @pat1,
            @p2 = @pat2,
            @cnt = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @cnt);

    FETCH NEXT FROM tcur INTO @schema, @table;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;
