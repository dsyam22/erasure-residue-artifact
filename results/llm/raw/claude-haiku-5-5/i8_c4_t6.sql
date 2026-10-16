SET NOCOUNT ON;

CREATE TABLE #scan (
    object_name nvarchar(300) NOT NULL,
    rows_found  int           NOT NULL
);

DECLARE @oid   int,
        @name  nvarchar(300),
        @pred  nvarchar(max),
        @q     nvarchar(max),
        @cnt   int;

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id,
           QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tcur;
FETCH NEXT FROM tcur INTO @oid, @name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @cnt = 0;

    -- Build a predicate matching any erased personal-data value in any character/LOB column
    SELECT @pred = STRING_AGG(CAST(
        N'(CHARINDEX(N''Subject_0000042'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0'
      + N' OR CHARINDEX(N''subject42@example.invalid'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0'
      + N' OR CHARINDEX(N''+1-555-0000042'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0)'
        AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.system_type_id
    WHERE c.object_id = @oid
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'sysname',
                      N'text', N'ntext', N'xml');

    IF @pred IS NOT NULL
    BEGIN
        SET @q = N'SELECT @cnt = COUNT(*) FROM ' + @name + N' WHERE ' + @pred;
        EXEC sp_executesql @q, N'@cnt int OUTPUT', @cnt = @cnt OUTPUT;
    END

    INSERT INTO #scan (object_name, rows_found) VALUES (@name, ISNULL(@cnt, 0));

    FETCH NEXT FROM tcur INTO @oid, @name;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #scan
ORDER BY object_name;

DROP TABLE #scan;
