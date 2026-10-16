SET NOCOUNT ON;

CREATE TABLE #results
(
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE
    @schema sysname,
    @table  sysname,
    @obj    nvarchar(400),
    @pred   nvarchar(max),
    @sql    nvarchar(max),
    @cnt    bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s
        ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @pred = NULL;

    -- Build a predicate matching the subject's identifiers in every
    -- character column (containment) and in customer_id (int equality).
    SELECT @pred = STRING_AGG(CAST(
        CASE
            WHEN c.system_type_id = 56 AND c.name = N'customer_id'
                THEN QUOTENAME(c.name) + N' = 42'
            ELSE
                N'CHARINDEX(N''Subject_0000042'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0'
              + N' OR CHARINDEX(N''subject42@example.invalid'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0'
              + N' OR CHARINDEX(N''+1-555-0000042'', CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0'
        END AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(@obj)
      AND (c.system_type_id IN (167, 175, 231, 239)   -- varchar, char, nvarchar, nchar
           OR (c.system_type_id = 56 AND c.name = N'customer_id'));  -- int

    IF @pred IS NULL
    BEGIN
        INSERT INTO #results (object_name, rows_found)
        VALUES (@schema + N'.' + @table, 0);
    END
    ELSE
    BEGIN
        SET @sql = N'SELECT @cnt_out = COUNT_BIG(*) FROM ' + @obj + N' WHERE ' + @pred + N';';
        SET @cnt = 0;
        EXEC sys.sp_executesql
            @sql,
            N'@cnt_out bigint OUTPUT',
            @cnt_out = @cnt OUTPUT;

        INSERT INTO #results (object_name, rows_found)
        VALUES (@schema + N'.' + @table, ISNULL(@cnt, 0));
    END

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
