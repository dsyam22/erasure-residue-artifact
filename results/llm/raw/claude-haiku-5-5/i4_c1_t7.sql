SET NOCOUNT ON;

-- Original personal data of the data subject (customer_id 42 / member_id 42)
DECLARE @vals TABLE (val nvarchar(200) NOT NULL);
INSERT INTO @vals (val) VALUES
    (N'Subject_0000042'),
    (N'subject42@example.invalid'),
    (N'+1-555-0000042');

CREATE TABLE #results (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @objname nvarchar(300),
        @pred nvarchar(max), @sql nvarchar(max);

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tcur;
FETCH NEXT FROM tcur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @objname = @schema + N'.' + @table;
    SET @pred = NULL;

    -- Build a predicate: any character column contains any original value
    SELECT @pred = STRING_AGG(
        CAST(N'CHARINDEX(N''' + REPLACE(v.val, N'''', N'''''') + N''', CAST('
             + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0' AS nvarchar(max)),
        N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    CROSS JOIN @vals AS v
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar');

    IF @pred IS NULL
        SET @sql = N'SELECT N''' + REPLACE(@objname, N'''', N'''''') + N''' AS object_name, CAST(0 AS bigint) AS rows_found;';
    ELSE
        SET @sql = N'SELECT N''' + REPLACE(@objname, N'''', N'''''') + N''' AS object_name, '
                 + N'CAST(COUNT(*) AS bigint) AS rows_found FROM '
                 + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';

    INSERT INTO #results (object_name, rows_found)
    EXEC sp_executesql @sql;

    FETCH NEXT FROM tcur INTO @schema, @table;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
