SET NOCOUNT ON;

CREATE TABLE #results (
    object_name nvarchar(400) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @v1 nvarchar(200) = N'Subject_0000042',
        @v2 nvarchar(200) = N'subject42@example.invalid',
        @v3 nvarchar(200) = N'+1-555-0000042';

DECLARE @schema sysname, @table sysname, @oid int,
        @pred nvarchar(max), @sql nvarchar(max), @obj nvarchar(400);

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table, @oid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj = @schema + N'.' + @table;
    SET @pred = NULL;

    SELECT @pred = STRING_AGG(CAST(
        N'(CHARINDEX(@v1, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) COLLATE Latin1_General_CI_AS) > 0'
      + N' OR CHARINDEX(@v2, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) COLLATE Latin1_General_CI_AS) > 0'
      + N' OR CHARINDEX(@v3, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) COLLATE Latin1_General_CI_AS) > 0)'
        AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = @oid
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'text', N'ntext');

    IF @pred IS NULL
    BEGIN
        INSERT INTO #results (object_name, rows_found) VALUES (@obj, 0);
    END
    ELSE
    BEGIN
        SET @sql = N'INSERT INTO #results (object_name, rows_found) SELECT @obj, COUNT_BIG(*) FROM '
                 + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';

        EXEC sp_executesql
            @sql,
            N'@v1 nvarchar(200), @v2 nvarchar(200), @v3 nvarchar(200), @obj nvarchar(400)',
            @v1 = @v1, @v2 = @v2, @v3 = @v3, @obj = @obj;
    END

    FETCH NEXT FROM tbl_cur INTO @schema, @table, @oid;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
