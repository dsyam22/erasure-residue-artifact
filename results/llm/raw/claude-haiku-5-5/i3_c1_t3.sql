SET NOCOUNT ON;

DECLARE @vals TABLE (v nvarchar(200) NOT NULL);
INSERT INTO @vals (v)
VALUES (N'Subject_0000042'),
       (N'subject42@example.invalid'),
       (N'+1-555-0000042');

CREATE TABLE #results (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @oid    int,
        @qname  nvarchar(300),
        @obj    nvarchar(300),
        @pred   nvarchar(max),
        @sql    nvarchar(max),
        @cnt    bigint;

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id,
           QUOTENAME(s.name) + N'.' + QUOTENAME(t.name),
           s.name + N'.' + t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tcur;
FETCH NEXT FROM tcur INTO @oid, @qname, @obj;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @cnt  = 0;

    -- Build predicate: any character column contains any of the subject's values
    SELECT @pred = STRING_AGG(
               CAST(N'CHARINDEX(N''' + REPLACE(v.v, N'''', N'''''') + N''', '
                    + QUOTENAME(c.name) + N' COLLATE Latin1_General_CI_AS) > 0'
                    AS nvarchar(max)),
               N' OR ')
    FROM sys.columns AS c
    CROSS JOIN @vals AS v
    WHERE c.object_id = @oid
      AND c.system_type_id IN (167, 175, 231, 239); -- varchar, char, nvarchar, nchar

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @c = COUNT_BIG(*) FROM ' + @qname + N' WHERE ' + @pred + N';';
        EXEC sys.sp_executesql @sql, N'@c bigint OUTPUT', @c = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found) VALUES (@obj, ISNULL(@cnt, 0));

    FETCH NEXT FROM tcur INTO @oid, @qname, @obj;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
