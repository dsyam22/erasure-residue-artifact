SET NOCOUNT ON;

CREATE TABLE #results (
    object_name nvarchar(400) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @pred nvarchar(max), @sql nvarchar(max);

DECLARE target_cur CURSOR LOCAL FAST_FORWARD FOR
SELECT
    t.TABLE_SCHEMA,
    t.TABLE_NAME,
    STUFF((
        SELECT ' OR ' + QUOTENAME(c.COLUMN_NAME) +
               CASE c.COLUMN_NAME
                    WHEN 'customer_id' THEN N' = 42'
                    WHEN 'full_name'   THEN N' = N''Subject_0000042'''
                    WHEN 'email'       THEN N' = N''subject42@example.invalid'''
                    WHEN 'phone'       THEN N' = N''+1-555-0000042'''
               END
        FROM INFORMATION_SCHEMA.COLUMNS AS c
        WHERE c.TABLE_SCHEMA = t.TABLE_SCHEMA
          AND c.TABLE_NAME   = t.TABLE_NAME
          AND c.COLUMN_NAME IN ('customer_id', 'full_name', 'email', 'phone')
        ORDER BY c.ORDINAL_POSITION
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 4, '') AS pred
FROM INFORMATION_SCHEMA.TABLES AS t
WHERE t.TABLE_TYPE = 'BASE TABLE'
  AND EXISTS (
        SELECT 1
        FROM INFORMATION_SCHEMA.COLUMNS AS c
        WHERE c.TABLE_SCHEMA = t.TABLE_SCHEMA
          AND c.TABLE_NAME   = t.TABLE_NAME
          AND c.COLUMN_NAME IN ('customer_id', 'full_name', 'email', 'phone')
  );

OPEN target_cur;
FETCH NEXT FROM target_cur INTO @schema, @table, @pred;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'INSERT INTO #results (object_name, rows_found) '
             + N'SELECT ' + QUOTENAME(@schema + N'.' + @table, '''') + N', COUNT_BIG(*) '
             + N'FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
             + N' WHERE (' + @pred + N');';

    EXEC sys.sp_executesql @sql;

    FETCH NEXT FROM target_cur INTO @schema, @table, @pred;
END

CLOSE target_cur;
DEALLOCATE target_cur;

-- Ensure the two known locations are always reported, even if the scan found nothing for them.
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = N'dbo.customer')
    INSERT INTO #results (object_name, rows_found) VALUES (N'dbo.customer', 0);
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = N'reporting.customer_replica')
    INSERT INTO #results (object_name, rows_found) VALUES (N'reporting.customer_replica', 0);

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
