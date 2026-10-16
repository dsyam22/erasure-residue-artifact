SET NOCOUNT ON;

DECLARE @v1 nvarchar(100) = N'Subject_0000042';
DECLARE @v2 nvarchar(100) = N'subject42@example.invalid';
DECLARE @v3 nvarchar(100) = N'+1-555-0000042';

CREATE TABLE #results
(
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @oid int;
DECLARE @pred nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl;
FETCH NEXT FROM tbl INTO @schema, @table, @oid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @cnt = 0;

    -- Build a predicate that checks every character column for any of the three original values
    SELECT @pred = STRING_AGG(
               N'CHARINDEX(@v1, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0'
             + N' OR CHARINDEX(@v2, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0'
             + N' OR CHARINDEX(@v3, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0',
               N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = @oid
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'sysname');

    IF @pred IS NULL
    BEGIN
        INSERT INTO #results (object_name, rows_found)
        VALUES (@schema + N'.' + @table, 0);
    END
    ELSE
    BEGIN
        SET @sql = N'SELECT @cnt_out = COUNT(*) FROM '
                 + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';

        EXEC sys.sp_executesql
             @sql,
             N'@v1 nvarchar(100), @v2 nvarchar(100), @v3 nvarchar(100), @cnt_out bigint OUTPUT',
             @v1 = @v1, @v2 = @v2, @v3 = @v3, @cnt_out = @cnt OUTPUT;

        INSERT INTO #results (object_name, rows_found)
        VALUES (@schema + N'.' + @table, @cnt);
    END

    FETCH NEXT FROM tbl INTO @schema, @table, @oid;
END

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
