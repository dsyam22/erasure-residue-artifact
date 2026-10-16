SET NOCOUNT ON;

DECLARE @vals TABLE (val nvarchar(100) NOT NULL);
INSERT INTO @vals (val)
VALUES (N'Subject_0000042'),
       (N'subject42@example.invalid'),
       (N'+1-555-0000042');

CREATE TABLE #results (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @tq   nvarchar(300),
        @tn   nvarchar(300),
        @cond nvarchar(max),
        @sql  nvarchar(max),
        @n    bigint;

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name),
           s.name + N'.' + t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tcur;
FETCH NEXT FROM tcur INTO @tq, @tn;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cond = NULL;
    SET @n = 0;

    SELECT @cond = STRING_AGG(
               CAST(N'CHARINDEX(N''' + v.val + N''', CAST(' + QUOTENAME(c.name)
                    + N' AS nvarchar(max))) > 0' AS nvarchar(max)),
               N' OR ')
    FROM sys.columns AS c
    CROSS JOIN @vals AS v
    WHERE c.object_id = OBJECT_ID(@tq)
      AND c.system_type_id IN (167, 175, 231, 239);  -- varchar, char, nvarchar, nchar

    IF @cond IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n_out = COUNT(*) FROM ' + @tq + N' WHERE ' + @cond + N';';
        EXEC sys.sp_executesql @sql,
             N'@n_out bigint OUTPUT',
             @n_out = @n OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found) VALUES (@tn, @n);

    FETCH NEXT FROM tcur INTO @tq, @tn;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
