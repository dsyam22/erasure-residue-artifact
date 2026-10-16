SET NOCOUNT ON;

CREATE TABLE #r (object_name sysname NOT NULL, rows_found bigint NOT NULL);

DECLARE @schema sysname, @table sysname, @cond nvarchar(max), @q nvarchar(max);

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cond = NULL;

    -- Build a predicate: any text column contains any original personal value
    SELECT @cond = STRING_AGG(CAST(
        N'(CHARINDEX(N''Subject_0000042'', ' + QUOTENAME(col.name) + N') > 0'
      + N' OR CHARINDEX(N''subject42@example.invalid'', ' + QUOTENAME(col.name) + N') > 0'
      + N' OR CHARINDEX(N''+1-555-0000042'', ' + QUOTENAME(col.name) + N') > 0)'
      AS nvarchar(max)), N' OR ')
    FROM sys.columns col
    JOIN sys.types ty ON ty.user_type_id = col.user_type_id
    WHERE col.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND ty.name IN ('char', 'varchar', 'nchar', 'nvarchar');

    IF @cond IS NULL
    BEGIN
        -- No text columns: nothing can hold the personal data here
        INSERT INTO #r (object_name, rows_found)
        VALUES (CONVERT(sysname, @schema + N'.' + @table), 0);
    END
    ELSE
    BEGIN
        SET @q = N'INSERT INTO #r (object_name, rows_found) SELECT N'''
               + REPLACE(@schema + N'.' + @table, N'''', N'''''')
               + N''', COUNT_BIG(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
               + N' WHERE ' + @cond + N';';
        EXEC sys.sp_executesql @q;
    END

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #r
ORDER BY object_name;

DROP TABLE #r;
