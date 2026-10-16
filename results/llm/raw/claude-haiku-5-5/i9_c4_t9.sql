USE llm_i9;
SET NOCOUNT ON;

CREATE TABLE #results (
    object_name nvarchar(400) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @id   int,
        @obj  nvarchar(400),
        @pred nvarchar(max),
        @sql  nvarchar(max);

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id, QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;

OPEN tcur;
FETCH NEXT FROM tcur INTO @id, @obj;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;

    -- Build a predicate over string columns (exact subject values) and customer_id = 42 (int)
    SELECT @pred = STRING_AGG(CAST(
        CASE WHEN c.system_type_id = 56
             THEN QUOTENAME(c.name) + N' = 42'
             ELSE N'CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE ''%Subject[_]0000042%'''
                + N' OR CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE ''%subject42@example.invalid%'''
                + N' OR CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE ''%+1-555-0000042%'''
        END AS nvarchar(max)), N' OR ')
    FROM sys.columns c
    WHERE c.object_id = @id
      AND (c.system_type_id IN (167, 175, 231, 239)
           OR (c.name = N'customer_id' AND c.system_type_id = 56));

    IF @pred IS NULL
    BEGIN
        INSERT INTO #results (object_name, rows_found) VALUES (@obj, 0);
    END
    ELSE
    BEGIN
        SET @sql = N'INSERT INTO #results (object_name, rows_found) SELECT N'''
                 + REPLACE(@obj, '''', '''''')
                 + N''', COUNT_BIG(*) FROM ' + @obj
                 + N' WHERE ' + @pred + N';';
        EXEC sys.sp_executesql @sql;
    END

    FETCH NEXT FROM tcur INTO @id, @obj;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;
