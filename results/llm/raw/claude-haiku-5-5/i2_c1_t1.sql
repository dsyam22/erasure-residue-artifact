SET NOCOUNT ON;

CREATE TABLE #result (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @pred nvarchar(max), @sql nvarchar(max), @n bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.TABLE_SCHEMA, t.TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES AS t
    WHERE t.TABLE_TYPE = 'BASE TABLE'
    ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @n = 0;

    -- Build one predicate: any character column contains any of the subject's original personal data
    SELECT @pred = STRING_AGG(
            CONVERT(nvarchar(max),
                N'CHARINDEX(' + v.val + N', CAST(' + QUOTENAME(c.COLUMN_NAME) + N' AS nvarchar(max))) > 0'),
            N' OR ')
    FROM INFORMATION_SCHEMA.COLUMNS AS c
    CROSS JOIN (VALUES
        (N'N''Subject_0000042'''),
        (N'N''subject42@example.invalid'''),
        (N'N''+1-555-0000042''')
    ) AS v(val)
    WHERE c.TABLE_SCHEMA = @schema
      AND c.TABLE_NAME   = @table
      AND c.DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar');

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n = COUNT_BIG(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';
        EXEC sp_executesql @sql, N'@n bigint OUTPUT', @n = @n OUTPUT;
    END

    INSERT INTO #result (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @n);

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #result
ORDER BY object_name;

DROP TABLE #result;
