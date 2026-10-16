DECLARE @HistoryTableName NVARCHAR(260);
DECLARE @sql NVARCHAR(MAX);

SELECT @HistoryTableName = QUOTENAME(SCHEMA_NAME(h.schema_id)) + '.' + QUOTENAME(h.name)
FROM sys.tables t
JOIN sys.tables h ON t.history_table_id = h.object_id
WHERE t.object_id = OBJECT_ID('dbo.customer');

SET @sql = N'
SELECT ''dbo.customer'' AS object_name, COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = 42 
   OR full_name = ''Subject_0000042'' 
   OR email = ''subject42@example.invalid'' 
   OR phone = ''+1-555-0000042''
';

IF @HistoryTableName IS NOT NULL
BEGIN
    SET @sql = @sql + N'
UNION ALL
SELECT ''' + REPLACE(REPLACE(@HistoryTableName, '[', ''), ']', '') + ''' AS object_name, COUNT(*) AS rows_found
FROM ' + @HistoryTableName + N'
WHERE customer_id = 42 
   OR full_name = ''Subject_0000042'' 
   OR email = ''subject42@example.invalid'' 
   OR phone = ''+1-555-0000042''
';
END

EXEC sp_executesql @sql;
