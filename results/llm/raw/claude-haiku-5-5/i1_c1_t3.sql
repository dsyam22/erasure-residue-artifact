SET NOCOUNT ON;

-- Results: one row per scanned table (rows still containing the subject's original personal data).
CREATE TABLE #scan
(
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

-- Subject's original personal data (customer_id is an int and too generic to match on its own).
DECLARE @vals TABLE (val nvarchar(200) NOT NULL);
INSERT INTO @vals (val) VALUES
    (N'Subject_0000042'),
    (N'subject42@example.invalid'),
    (N'+1-555-0000042');

DECLARE @schema sysname, @table sysname, @objid int;
DECLARE @where nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tcur;
FETCH NEXT FROM tcur INTO @schema, @table, @objid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @where = NULL;
    SET @cnt = 0;

    -- Build a predicate: any character-type column of this table contains any of the subject's values.
    SELECT @where = STRING_AGG(
            CAST(N'(CHARINDEX(N''' + v.val + N''', CONVERT(nvarchar(max), '
                 + QUOTENAME(c.name) + N')) > 0)' AS nvarchar(max)),
            N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    CROSS JOIN @vals AS v
    WHERE c.object_id = @objid
      AND ty.name IN ('char', 'varchar', 'nchar', 'nvarchar', 'text', 'ntext');

    IF @where IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @c = COUNT_BIG(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @where + N';';
        EXEC sp_executesql @sql, N'@c bigint OUTPUT', @c = @cnt OUTPUT;
    END

    INSERT INTO #scan (object_name, rows_found)
    VALUES (CAST(@schema + N'.' + @table AS sysname), @cnt);

    FETCH NEXT FROM tcur INTO @schema, @table, @objid;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #scan
ORDER BY object_name;

DROP TABLE #scan;
