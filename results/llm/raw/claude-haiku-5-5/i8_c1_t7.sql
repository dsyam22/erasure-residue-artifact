SET NOCOUNT ON;

DECLARE @p1 nvarchar(100) = N'Subject_0000042';
DECLARE @p2 nvarchar(100) = N'subject42@example.invalid';
DECLARE @p3 nvarchar(100) = N'+1-555-0000042';

CREATE TABLE #res (
    object_name nvarchar(517) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname;
DECLARE @obj nvarchar(517), @cond nvarchar(max), @sql nvarchar(max), @cnt bigint;

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
    SET @obj  = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @cond = NULL;
    SET @cnt  = 0;

    SELECT @cond = STRING_AGG(
        CONVERT(nvarchar(max),
            N'(CHARINDEX(@p1, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) COLLATE Latin1_General_CI_AS) > 0'
          + N' OR CHARINDEX(@p2, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) COLLATE Latin1_General_CI_AS) > 0'
          + N' OR CHARINDEX(@p3, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) COLLATE Latin1_General_CI_AS) > 0)'),
        N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(@obj)
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'text', N'ntext', N'xml');

    IF @cond IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @cnt_out = COUNT(*) FROM ' + @obj + N' WHERE ' + @cond + N';';

        EXEC sp_executesql
            @sql,
            N'@p1 nvarchar(100), @p2 nvarchar(100), @p3 nvarchar(100), @cnt_out bigint OUTPUT',
            @p1 = @p1, @p2 = @p2, @p3 = @p3,
            @cnt_out = @cnt OUTPUT;
    END

    INSERT INTO #res (object_name, rows_found) VALUES (@obj, @cnt);

    FETCH NEXT FROM tcur INTO @schema, @table;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #res
ORDER BY object_name;

DROP TABLE #res;
