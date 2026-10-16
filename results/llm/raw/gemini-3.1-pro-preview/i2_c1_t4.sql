SET NOCOUNT ON;
DECLARE @results TABLE (object_name NVARCHAR(256), rows_found INT);

-- Check main table
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = 42 
   OR full_name = 'Subject_0000042' 
   OR email = 'subject42@example.invalid' 
   OR phone = '+1-555-0000042';

-- Check temporal history table if it exists
DECLARE @HistorySchema NVARCHAR(128);
DECLARE @HistoryTable NVARCHAR(128);
DECLARE @HistoryFullName NVARCHAR(256);

SELECT 
    @HistorySchema = SCHEMA_NAME(h.schema_id),
    @HistoryTable = h.name,
    @HistoryFullName = SCHEMA_NAME(h.schema_id) + '.' + h.name
FROM sys.tables t
JOIN sys.tables h ON t.history_table_id = h.object_id
WHERE t.object_id = OBJECT_ID('dbo.customer');

IF @HistoryFullName IS NOT NULL
BEGIN
    DECLARE @sql NVARCHAR(MAX) = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@HistorySchema) + '.' + QUOTENAME(@HistoryTable) + 
        N' WHERE customer_id = 42 OR full_name = ''Subject_0000042'' OR email = ''subject42@example.invalid'' OR phone = ''+1-555-0000042'';';
    DECLARE @cnt INT;
    EXEC sp_executesql @sql, N'@cnt INT OUTPUT', @cnt OUTPUT;
    
    INSERT INTO @results (object_name, rows_found)
    VALUES (@HistoryFullName, @cnt);
END

-- Return final result set
SELECT object_name, rows_found 
FROM @results;
