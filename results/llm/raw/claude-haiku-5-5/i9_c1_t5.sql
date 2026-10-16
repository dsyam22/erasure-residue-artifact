SET NOCOUNT ON;

DECLARE @p1 nvarchar(200) = N'subject42@example.invalid';
DECLARE @p2 nvarchar(200) = N'+1-555-0000042';
DECLARE @p3 nvarchar(200) = N'Subject_0000042';

IF OBJECT_ID('tempdb..#results') IS NOT NULL DROP TABLE #results;
CREATE TABLE #results (
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

IF OBJECT_ID('tempdb..#targets') IS NOT NULL DROP TABLE #targets;
CREATE TABLE #targets (
    schema_name sysname NOT NULL,
    table_name  sysname NOT NULL,
    predicate   nvarchar(max) NOT NULL
);

-- One target per base table that has character columns; predicate matches any column containing any of the subject's original values.
INSERT INTO #targets (schema_name, table_name, predicate)
SELECT
    c.TABLE_SCHEMA,
    c.TABLE_NAME,
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'(CHARINDEX(@p1, CAST(' + QUOTENAME(c.COLUMN_NAME) + N' AS nvarchar(max))) > 0 OR ' +
            N'CHARINDEX(@p2, CAST(' + QUOTENAME(c.COLUMN_NAME) + N' AS nvarchar(max))) > 0 OR ' +
            N'CHARINDEX(@p3, CAST(' + QUOTENAME(c.COLUMN_NAME) + N' AS nvarchar(max))) > 0)'),
        N' OR ')
FROM INFORMATION_SCHEMA.COLUMNS AS c
JOIN INFORMATION_SCHEMA.TABLES AS t
  ON t.TABLE_SCHEMA = c.TABLE_SCHEMA
 AND t.TABLE_NAME   = c.TABLE_NAME
 AND t.TABLE_TYPE   = 'BASE TABLE'
WHERE c.DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar')
GROUP BY c.TABLE_SCHEMA, c.TABLE_NAME;

DECLARE @schema sysname, @table sysname, @pred nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE target_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT schema_name, table_name, predicate FROM #targets ORDER BY schema_name, table_name;

OPEN target_cur;
FETCH NEXT FROM target_cur INTO @schema, @table, @pred;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cnt = 0;
    SET @sql = N'SELECT @cnt = COUNT_BIG(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
             + N' WHERE ' + @pred + N';';

    EXEC sys.sp_executesql
         @sql,
         N'@p1 nvarchar(200), @p2 nvarchar(200), @p3 nvarchar(200), @cnt bigint OUTPUT',
         @p1 = @p1, @p2 = @p2, @p3 = @p3, @cnt = @cnt OUTPUT;

    INSERT INTO #results (object_name, rows_found)
    VALUES (CONCAT(@schema, N'.', @table), @cnt);

    FETCH NEXT FROM target_cur INTO @schema, @table, @pred;
END

CLOSE target_cur;
DEALLOCATE target_cur;

-- Tables with no character columns cannot hold the subject's text values; report them as 0 as well.
INSERT INTO #results (object_name, rows_found)
SELECT CONCAT(t.TABLE_SCHEMA, N'.', t.TABLE_NAME), 0
FROM INFORMATION_SCHEMA.TABLES AS t
WHERE t.TABLE_TYPE = 'BASE TABLE'
  AND NOT EXISTS (SELECT 1 FROM #targets AS x
                  WHERE x.schema_name = t.TABLE_SCHEMA AND x.table_name = t.TABLE_NAME);

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;
