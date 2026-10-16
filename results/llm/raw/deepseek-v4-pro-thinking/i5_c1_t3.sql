SET NOCOUNT ON;

CREATE TABLE #Results (
    object_name nvarchar(500) NOT NULL,
    rows_found bigint NOT NULL
);

DECLARE @schema sysname;
DECLARE @table sysname;
DECLARE @object_id int;
DECLARE @conditions nvarchar(max);
DECLARE @sql nvarchar(max);
DECLARE @count bigint;

DECLARE table_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON t.schema_id = s.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN table_cursor;

FETCH NEXT FROM table_cursor INTO @schema, @table, @object_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @conditions = NULL;
    SET @count = 0;

    SELECT @conditions = STRING_AGG(
        CASE
            WHEN ty.name IN ('char', 'varchar', 'nchar', 'nvarchar') THEN
                QUOTENAME(c.name) + N' IN (N''Subject_0000042'', N''subject42@example.invalid'', N''+1-555-0000042'', N''42'')'
            WHEN ty.name IN ('text', 'ntext') THEN
                N'CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N') IN (N''Subject_0000042'', N''subject42@example.invalid'', N''+1-555-0000042'', N''42'')'
            WHEN ty.name IN ('tinyint', 'smallint', 'int', 'bigint', 'decimal', 'numeric', 'money', 'smallmoney', 'float', 'real') THEN
                QUOTENAME(c.name) + N' = 42'
            ELSE NULL
        END,
        N' OR '
    )
    FROM sys.columns AS c
    JOIN sys.types AS ty
        ON ty.user_type_id = c.system_type_id
    WHERE c.object_id = @object_id;

    IF @conditions IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @count = COUNT(*) FROM '
            + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
            + N' WHERE ' + @conditions;

        EXEC sp_executesql @sql, N'@count bigint OUTPUT', @count OUTPUT;
    END;

    INSERT INTO #Results (object_name, rows_found)
    VALUES (CONCAT(@schema, '.', @table), @count);

    FETCH NEXT FROM table_cursor INTO @schema, @table, @object_id;
END;

CLOSE table_cursor;
DEALLOCATE table_cursor;

SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;
