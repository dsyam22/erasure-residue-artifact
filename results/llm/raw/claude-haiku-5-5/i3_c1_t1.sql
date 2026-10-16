SET NOCOUNT ON;

DECLARE @n nvarchar(200) = N'Subject_0000042';
DECLARE @e nvarchar(200) = N'subject42@example.invalid';
DECLARE @p nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(300) NOT NULL,
    rows_found  int           NOT NULL
);

DECLARE @schema sysname, @table sysname, @oid int;
DECLARE @pred nvarchar(max), @sql nvarchar(max), @obj nvarchar(400);
DECLARE @cnt int;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tbl;
FETCH NEXT FROM tbl INTO @schema, @table, @oid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @cnt = 0;
    SET @obj = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);

    SELECT @pred = STRING_AGG(
                       CAST(QUOTENAME(c.name) + N' IN (@n, @e, @p)' AS nvarchar(max)),
                       N' OR ')
                   WITHIN GROUP (ORDER BY c.column_id)
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = @oid
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar');

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + @obj + N' WHERE ' + @pred + N';';

        EXEC sp_executesql
            @sql,
            N'@n nvarchar(200), @e nvarchar(200), @p nvarchar(200), @cnt int OUTPUT',
            @n = @n, @e = @e, @p = @p, @cnt = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @cnt);

    FETCH NEXT FROM tbl INTO @schema, @table, @oid;
END

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
