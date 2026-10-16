SET NOCOUNT ON;

DECLARE @v1 nvarchar(200) = N'Subject_0000042',
        @v2 nvarchar(200) = N'subject42@example.invalid',
        @v3 nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @schema sysname, @table sysname, @pred nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;

OPEN tbl;
FETCH NEXT FROM tbl INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @cnt = 0;

    SELECT @pred = STRING_AGG(CAST(QUOTENAME(c.name) + N' IN (@v1, @v2, @v3)' AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND ty.name IN (N'nvarchar', N'varchar', N'nchar', N'char');

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';

        EXEC sp_executesql
             @sql,
             N'@v1 nvarchar(200), @v2 nvarchar(200), @v3 nvarchar(200), @n bigint OUTPUT',
             @v1 = @v1, @v2 = @v2, @v3 = @v3, @n = @cnt OUTPUT;
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
