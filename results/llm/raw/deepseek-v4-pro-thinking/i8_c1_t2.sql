SET NOCOUNT ON;

DROP TABLE IF EXISTS #Results;

CREATE TABLE #Results (
    object_name nvarchar(300) NOT NULL,
    rows_found bigint NOT NULL
);

DECLARE @schema_name sysname;
DECLARE @table_name sysname;
DECLARE @object_id int;
DECLARE @display_name nvarchar(300);
DECLARE @quoted_name nvarchar(300);
DECLARE @where nvarchar(max);
DECLARE @sql nvarchar(max);
DECLARE @rows bigint;

DECLARE table_cur CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
SELECT s.name, t.name, t.object_id
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

OPEN table_cur;

FETCH NEXT FROM table_cur INTO @schema_name, @table_name, @object_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @display_name = @schema_name + N'.' + @table_name;
    SET @quoted_name = QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name);

    SET @where = NULL;

    SELECT @where = STRING_AGG(cond, N' OR ')
    FROM (
        SELECT
            CASE
                WHEN c.name COLLATE Latin1_General_CI_AS = N'customer_id'
                     AND ty.name IN (N'tinyint', N'smallint', N'int', N'bigint', N'decimal', N'numeric', N'money', N'smallmoney', N'float', N'real')
                    THEN QUOTENAME(c.name) + N' = 42'
                WHEN c.name COLLATE Latin1_General_CI_AS = N'customer_id'
                     AND ty.name IN (N'varchar', N'nvarchar', N'char', N'nchar', N'text', N'ntext', N'sysname')
                    THEN N'CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N') = N''42'''
                WHEN ty.name IN (N'varchar', N'nvarchar', N'char', N'nchar', N'text', N'ntext', N'sysname')
                    THEN N'CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N') IN (N''Subject_0000042'', N''subject42@example.invalid'', N''+1-555-0000042'')'
                ELSE NULL
            END AS cond
        FROM sys.columns AS c
        INNER JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
        WHERE c.object_id = @object_id
    ) AS d
    WHERE cond IS NOT NULL;

    IF @where IS NOT NULL
    BEGIN
        SET @sql = N'SET NOCOUNT ON; SELECT @rows = COUNT_BIG(*) FROM ' + @quoted_name + N' WHERE ' + @where + N';';
        SET @rows = 0;
        EXEC sp_executesql @sql, N'@rows bigint OUTPUT', @rows OUTPUT;
    END
    ELSE
    BEGIN
        SET @rows = 0;
    END;

    INSERT INTO #Results (object_name, rows_found)
    VALUES (@display_name, @rows);

    FETCH NEXT FROM table_cur INTO @schema_name, @table_name, @object_id;
END;

CLOSE table_cur;
DEALLOCATE table_cur;

SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;
