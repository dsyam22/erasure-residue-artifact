SET NOCOUNT ON;

CREATE TABLE #results
(
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @schema sysname,
        @table  sysname,
        @obj    nvarchar(400),
        @pred   nvarchar(max),
        @sql    nvarchar(max),
        @cnt    bigint;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tbl;
FETCH NEXT FROM tbl INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @pred = NULL;
    SET @cnt = 0;

    -- Build a predicate covering the subject's original personal data:
    --  * full_name / email / phone values in any character column
    --  * customer_id = 42 in any integer-typed customer_id column
    SELECT @pred = N'(' + STRING_AGG(x.expr, N' OR ') + N')'
    FROM (
        SELECT
            CASE
                WHEN ty.name IN (N'nvarchar', N'varchar', N'nchar', N'char', N'sysname')
                    THEN N'CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) IN (N''Subject_0000042'', N''subject42@example.invalid'', N''+1-555-0000042'')'
                WHEN c.name = N'customer_id'
                 AND ty.name IN (N'int', N'bigint', N'smallint', N'tinyint', N'decimal', N'numeric')
                    THEN QUOTENAME(c.name) + N' = 42'
            END AS expr
        FROM sys.columns AS c
        JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
        WHERE c.object_id = OBJECT_ID(@obj)
    ) AS x
    WHERE x.expr IS NOT NULL;

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @c = COUNT_BIG(*) FROM ' + @obj + N' WHERE ' + @pred + N';';
        EXEC sp_executesql @sql, N'@c bigint OUTPUT', @c = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @cnt);

    FETCH NEXT FROM tbl INTO @schema, @table;
END

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
