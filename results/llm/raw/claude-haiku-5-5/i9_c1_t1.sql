SET NOCOUNT ON;

CREATE TABLE #vals (val nvarchar(200) NOT NULL);
INSERT INTO #vals (val) VALUES
    (N'Subject_0000042'),
    (N'subject42@example.invalid'),
    (N'+1-555-0000042');

CREATE TABLE #results (
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @oid int, @schema sysname, @table sysname;
DECLARE @pred nvarchar(max), @sql nvarchar(max), @obj nvarchar(300);

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id, s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @oid, @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);

    -- Build a predicate: a row matches if any character column contains any subject value
    SET @pred = NULL;
    SELECT @pred = STRING_AGG(CAST(
        N'EXISTS (SELECT 1 FROM #vals AS v WHERE CHARINDEX(v.val COLLATE Latin1_General_CI_AS, CAST(t.' + QUOTENAME(c.name)
        + N' AS nvarchar(max)) COLLATE Latin1_General_CI_AS) > 0)' AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = @oid
      AND c.system_type_id IN (167, 175, 231, 239);  -- varchar, char, nvarchar, nchar

    IF @pred IS NULL
        SET @sql = N'INSERT INTO #results (object_name, rows_found) VALUES (N'''
                 + REPLACE(@obj, N'''', N'''''') + N''', 0);';
    ELSE
        SET @sql = N'INSERT INTO #results (object_name, rows_found) '
                 + N'SELECT N''' + REPLACE(@obj, N'''', N'''''') + N''', COUNT_BIG(*) '
                 + N'FROM ' + @obj + N' AS t WHERE ' + @pred + N';';

    EXEC sys.sp_executesql @sql;

    FETCH NEXT FROM tbl_cur INTO @oid, @schema, @table;
END;

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
DROP TABLE #vals;
