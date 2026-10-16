SET NOCOUNT ON;

CREATE TABLE #r (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @s sysname, @t sysname, @obj nvarchar(300), @lit nvarchar(600),
        @cond nvarchar(max), @sql nvarchar(max);

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tcur;
FETCH NEXT FROM tcur INTO @s, @t;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj = @s + N'.' + @t;
    SET @lit = REPLACE(@obj, N'''', N'''''');
    SET @cond = NULL;

    SELECT @cond = STRING_AGG(CAST(
        N'(CHARINDEX(N''Subject_0000042'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0'
      + N' OR CHARINDEX(N''subject42@example.invalid'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0'
      + N' OR CHARINDEX(N''+1-555-0000042'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0)'
        AS nvarchar(max)), N' OR ')
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@s) + N'.' + QUOTENAME(@t))
      AND c.system_type_id IN (35, 99, 167, 175, 231, 239, 241); -- text, ntext, varchar, char, nvarchar, nchar, xml

    IF @cond IS NULL
        SET @sql = N'INSERT INTO #r (object_name, rows_found) SELECT N''' + @lit + N''', CAST(0 AS bigint);';
    ELSE
        SET @sql = N'INSERT INTO #r (object_name, rows_found) SELECT N''' + @lit + N''', CAST(COUNT(*) AS bigint) FROM '
                 + QUOTENAME(@s) + N'.' + QUOTENAME(@t)
                 + N' WHERE ' + @cond + N';';

    EXEC sys.sp_executesql @sql;

    FETCH NEXT FROM tcur INTO @s, @t;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #r
ORDER BY object_name;
