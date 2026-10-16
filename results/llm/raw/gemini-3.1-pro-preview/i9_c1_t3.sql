SET NOCOUNT ON;

DECLARE @Results TABLE (
    object_name NVARCHAR(512),
    rows_found INT
);

-- Check the current table
INSERT INTO @Results (object_name, rows_found)
SELECT 
    'dbo.customer', 
    COUNT(*)
FROM dbo.customer
WHERE customer_id = 42 
   OR full_name = 'Subject_0000042' 
   OR email = 'subject42@example.invalid' 
   OR phone = '+1-555-0000042';

-- Check for a system-versioned temporal history table
DECLARE @HistorySchema NVARCHAR(128);
DECLARE @HistoryTable NVARCHAR(128);
DECLARE @DynamicSQL NVARCHAR(MAX);

SELECT 
    @HistorySchema = s_hist.name, 
    @HistoryTable = t_hist.name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.tables t_hist ON t.history_table_id = t_hist.object_id
JOIN sys.schemas s_hist ON t_hist.schema_id = s_hist.schema_id
WHERE t.name = 'customer' AND s.name = 'dbo';

IF @HistoryTable IS NOT NULL
BEGIN
    SET @DynamicSQL = N'
        SELECT 
            ''' + @HistorySchema + '.' + @HistoryTable + ''', 
            COUNT(*) 
        FROM ' + QUOTENAME(@HistorySchema) + '.' + QUOTENAME(@HistoryTable) + '
        WHERE customer_id = 42 
           OR full_name = ''Subject_0000042'' 
           OR email = ''subject42@example.invalid'' 
           OR phone = ''+1-555-0000042'';';
           
    INSERT INTO @Results (object_name, rows_found)
    EXEC sp_executesql @DynamicSQL;
END

SET NOCOUNT OFF;

SELECT object_name, rows_found 
FROM @Results;
