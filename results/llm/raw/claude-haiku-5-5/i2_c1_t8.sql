SET NOCOUNT ON;

DECLARE @v1 nvarchar(200) = N'Subject_0000042';
DECLARE @v2 nvarchar(200) = N'subject42@example.invalid';
DECLARE @v3 nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results
(
    object_name sysname NOT NULL,
    rows_found  int     NOT NULL
);

DECLARE @oid int, @sn sysname, @tn sysname;
DECLARE @pred nvarchar(max), @sql nvarchar(max), @cnt int;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id, SCHEMA_NAME(t.schema_id), t.name
    FROM sys.tables AS t
    WHERE t.is_ms_shipped = 0
    ORDER BY SCHEMA_NAME(t.schema_id), t.name;

OPEN tbl;
FETCH NEXT FROM tbl INTO @oid, @sn, @tn;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @cnt = 0;

    SELECT @pred = STRING_AGG(
        N'(CHARINDEX(@v1, ' + x.expr + N') > 0 OR CHARINDEX(@v2, ' + x.expr +
        N') > 0 OR CHARINDEX(@v3, ' + x.expr + N') > 0)', N' OR ')
    FROM (
        SELECT CASE WHEN ty.name = N'xml'
                    THEN N'CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))'
                    ELSE QUOTENAME(c.name)
               END AS expr
        FROM sys.columns AS c
        JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
        WHERE c.object_id = @oid
          AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'xml')
    ) AS x;

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@sn) + N'.' + QUOTENAME(@tn)
                 + N' WHERE ' + @pred + N';';

        EXEC sp_executesql
            @sql,
            N'@v1 nvarchar(200), @v2 nvarchar(200), @v3 nvarchar(200), @cnt int OUTPUT',
            @v1 = @v1, @v2 = @v2, @v3 = @v3, @cnt = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@sn + N'.' + @tn, ISNULL(@cnt, 0));

    FETCH NEXT FROM tbl INTO @oid, @sn, @tn;
END

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
