SET NOCOUNT ON;

DECLARE @v_name  nvarchar(200) = N'Subject_0000042';
DECLARE @v_email nvarchar(200) = N'subject42@example.invalid';
DECLARE @v_phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #erasure_check
(
    object_name nvarchar(400) NOT NULL PRIMARY KEY,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @full nvarchar(400), @pred nvarchar(max),
        @sql nvarchar(max), @cnt bigint;

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
    SET @full = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @pred = NULL;
    SET @cnt  = 0;

    -- Build a predicate: any character column containing any of the subject's personal values
    SELECT @pred = STRING_AGG(CAST(
        N'(CHARINDEX(N''' + @v_name  + N''', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0'
      + N' OR CHARINDEX(N''' + @v_email + N''', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0'
      + N' OR CHARINDEX(N''' + @v_phone + N''', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0)'
        AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(@full)
      AND c.system_type_id IN (167, 175, 231, 239);   -- varchar, char, nvarchar, nchar

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @c = COUNT_BIG(*) FROM ' + @full + N' WHERE ' + @pred + N';';
        EXEC sp_executesql @sql, N'@c bigint OUTPUT', @c = @cnt OUTPUT;
    END

    INSERT INTO #erasure_check (object_name, rows_found)
    VALUES (@schema + N'.' + @table, ISNULL(@cnt, 0));

    FETCH NEXT FROM tcur INTO @schema, @table;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #erasure_check
ORDER BY object_name;

DROP TABLE #erasure_check;
