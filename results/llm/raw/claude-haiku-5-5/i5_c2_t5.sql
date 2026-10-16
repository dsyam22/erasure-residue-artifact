SET NOCOUNT ON;

CREATE TABLE #results (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @object_id int,
        @schema    sysname,
        @table     sysname,
        @where     nvarchar(max),
        @sql       nvarchar(max),
        @cnt       bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id, s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @object_id, @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @where = NULL;

    -- Build predicate: string columns containing any of the subject's original
    -- personal data values, plus customer_id = 42 where that column exists.
    SELECT @where = STUFF((
        SELECT N' OR ' +
               CASE
                   WHEN c.system_type_id = 56 THEN
                       QUOTENAME(c.name) + N' = 42'
                   ELSE
                       N'(CHARINDEX(N''Subject_0000042'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0' +
                       N' OR CHARINDEX(N''subject42@example.invalid'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0' +
                       N' OR CHARINDEX(N''+1-555-0000042'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0)'
               END
        FROM sys.columns AS c
        WHERE c.object_id = @object_id
          AND (c.system_type_id IN (167, 175, 231, 239)
               OR (c.system_type_id = 56 AND c.name = N'customer_id'))
        ORDER BY c.column_id
        FOR XML PATH(N''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 4, N'');

    SET @cnt = 0;

    IF @where IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n = COUNT_BIG(*) FROM '
                 + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @where + N';';

        EXEC sp_executesql @sql, N'@n bigint OUTPUT', @n = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @cnt);

    FETCH NEXT FROM tbl_cur INTO @object_id, @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
