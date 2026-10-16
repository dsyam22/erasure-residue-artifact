SET NOCOUNT ON;

CREATE TABLE #Results (
    object_name NVARCHAR(256),
    rows_found INT
);

DECLARE @HistoryTableName NVARCHAR(256);
SELECT @HistoryTableName = QUOTENAME(SCHEMA_NAME(h.schema_id)) + '.' + QUOTENAME(h.name)
FROM sys.tables t
JOIN sys.tables h ON t.history_table_id = h.object_id
WHERE t.object_id = OBJECT_ID('dbo.customer');

DECLARE @Sql NVARCHAR(MAX);

-- Check main table
SET @Sql = N'
INSERT INTO #Results (object_name, rows_found)
SELECT ''dbo.customer'', COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = ''Subject_0000042''
   OR email = ''subject42@example.invalid''
   OR phone = ''+1-555-0000042'';
';
EXEC sp_executesql @Sql;

-- Check history table if it exists
IF @HistoryTableName IS NOT NULL
BEGIN
    SET @Sql = N'
    INSERT INTO #Results (object_name, rows_found)
    SELECT ''' + REPLACE(@HistoryTableName, '"', '') + ''', COUNT(*)
    FROM ' + @HistoryTableName + '
    WHERE customer_id = 42
       OR full_name = ''Subject_0000042''
       OR email = ''subject42@example.invalid''
       OR phone = ''+1-555-0000042'';
    ';
    EXEC sp_executesql @Sql;
END

SET NOCOUNT OFF;

SELECT object_name, rows_found
FROM #Results;

DROP TABLE #Results;
