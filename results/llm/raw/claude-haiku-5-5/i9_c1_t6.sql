SET NOCOUNT ON;

CREATE TABLE #hits
(
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @obj nvarchar(300), @qobj nvarchar(300),
        @pred nvarchar(max), @sql nvarchar(max);

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj  = @schema + N'.' + @table;
    SET @qobj = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @pred = NULL;

    -- Build an OR-predicate over all character columns for the three personal-data values
    -- (full_name, email, phone). LIKE patterns escape '_' so the literal underscore matches.
    SELECT @pred = STRING_AGG(CAST(x.p AS nvarchar(max)), N' OR ')
    FROM (
        SELECT
            QUOTENAME(c.name) + N' LIKE N''%Subject\_0000042%'' ESCAPE ''\'''
          + N' OR ' + QUOTENAME(c.name) + N' LIKE N''%subject42@example.invalid%'' ESCAPE ''\'''
          + N' OR ' + QUOTENAME(c.name) + N' LIKE N''%+1-555-0000042%'' ESCAPE ''\''' AS p
        FROM sys.columns AS c
        WHERE c.object_id = OBJECT_ID(@qobj)
          AND c.system_type_id IN (167, 175, 231, 239)  -- varchar, char, nvarchar, nchar
    ) AS x;

    IF @pred IS NULL
    BEGIN
        INSERT #hits (object_name, rows_found) VALUES (@obj, 0);
    END
    ELSE
    BEGIN
        SET @sql = N'INSERT #hits (object_name, rows_found) '
                 + N'SELECT N''' + REPLACE(@obj, N'''', N'''''') + N''', COUNT_BIG(*) '
                 + N'FROM ' + @qobj + N' WHERE (' + @pred + N');';
        EXEC sys.sp_executesql @sql;
    END

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #hits
ORDER BY object_name;

DROP TABLE #hits;
