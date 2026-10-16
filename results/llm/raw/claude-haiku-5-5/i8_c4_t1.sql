SET NOCOUNT ON;

CREATE TABLE #results (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @tbl TABLE (
    id     int IDENTITY(1,1) PRIMARY KEY,
    obj_id int NOT NULL,
    sch    sysname NOT NULL,
    tname  sysname NOT NULL
);

INSERT INTO @tbl (obj_id, sch, tname)
SELECT t.object_id, s.name, t.name
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0;

DECLARE @i    int = 1,
        @n    int = (SELECT COUNT(*) FROM @tbl),
        @objid int,
        @sch  sysname,
        @tn   sysname,
        @pred nvarchar(max),
        @sql  nvarchar(max),
        @cnt  bigint;

WHILE @i <= @n
BEGIN
    SELECT @objid = obj_id, @sch = sch, @tn = tname
    FROM @tbl WHERE id = @i;

    SET @pred = NULL;

    -- One predicate per candidate column; string columns are matched by containment
    -- against the three original personal values, and customer_id is matched to 42.
    SELECT @pred = STRING_AGG(CAST(q.p AS nvarchar(max)), N' OR ')
    FROM (
        SELECT
            CASE
                WHEN ty.name IN ('nvarchar','varchar','nchar','char') THEN
                    N'(CHARINDEX(N''Subject_0000042'', ' + QUOTENAME(c.name) + N') > 0'
                  + N' OR CHARINDEX(N''subject42@example.invalid'', ' + QUOTENAME(c.name) + N') > 0'
                  + N' OR CHARINDEX(N''+1-555-0000042'', ' + QUOTENAME(c.name) + N') > 0)'
                WHEN c.name = N'customer_id' AND ty.name IN ('int','bigint','smallint','tinyint') THEN
                    N'(' + QUOTENAME(c.name) + N' = 42)'
            END AS p
        FROM sys.columns AS c
        JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
        WHERE c.object_id = @objid
          AND (ty.name IN ('nvarchar','varchar','nchar','char')
               OR (c.name = N'customer_id' AND ty.name IN ('int','bigint','smallint','tinyint')))
    ) AS q
    WHERE q.p IS NOT NULL;

    IF @pred IS NULL
        SET @cnt = 0;
    ELSE
    BEGIN
        SET @sql = N'SELECT @c = COUNT(*) FROM ' + QUOTENAME(@sch) + N'.' + QUOTENAME(@tn)
                 + N' WHERE ' + @pred + N';';
        EXEC sp_executesql @sql, N'@c bigint OUTPUT', @c = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (CAST(@sch + N'.' + @tn AS nvarchar(300)), @cnt);

    SET @i += 1;
END

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;
