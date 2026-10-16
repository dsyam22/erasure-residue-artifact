SET NOCOUNT ON;

CREATE TABLE #results
(
    object_name nvarchar(260) NOT NULL PRIMARY KEY,
    rows_found  bigint        NOT NULL
);

DECLARE @oid   int,
        @name  nvarchar(260),
        @pred  nvarchar(max),
        @sql   nvarchar(max),
        @cnt   bigint;

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id,
           QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name)
    FROM sys.tables AS t
    WHERE t.is_ms_shipped = 0
    ORDER BY 2;

OPEN tcur;
FETCH NEXT FROM tcur INTO @oid, @name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @cnt  = 0;

    SELECT @pred = STRING_AGG(
               CAST(
                   N'(CHARINDEX(N''Subject_0000042'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0'
                 + N' OR CHARINDEX(N''subject42@example.invalid'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0'
                 + N' OR CHARINDEX(N''+1-555-0000042'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0)'
               AS nvarchar(max)), N' OR ')
               WITHIN GROUP (ORDER BY c.column_id)
    FROM sys.columns AS c
    JOIN sys.types AS ty
      ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = @oid
      AND ty.name IN (N'nvarchar', N'varchar', N'nchar', N'char', N'xml');

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n = COUNT_BIG(*) FROM ' + @name + N' WHERE ' + @pred + N';';
        EXEC sys.sp_executesql
             @sql,
             N'@n bigint OUTPUT',
             @n = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@name, @cnt);

    FETCH NEXT FROM tcur INTO @oid, @name;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
