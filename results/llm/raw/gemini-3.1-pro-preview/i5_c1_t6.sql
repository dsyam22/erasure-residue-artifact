SET NOCOUNT ON;

DECLARE @Results TABLE (
    object_name NVARCHAR(256),
    rows_found INT
);

-- Check the main table
INSERT INTO @Results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = 42 
   OR full_name = 'Subject_0000042' 
   OR email = 'subject42@example.invalid' 
   OR phone = '+1-555-0000042';

-- Check the history table if dbo.customer is a system-versioned temporal table
DECLARE @HistoryTableSchema NVARCHAR(128);
DECLARE @HistoryTableName NVARCHAR(128);
DECLARE @FullHistoryName NVARCHAR(256);

SELECT 
    @HistoryTableSchema = SCHEMA_NAME(h.schema_id), 
    @HistoryTableName = h.name,
    @FullHistoryName = SCHEMA_NAME(h.schema_id) + '.' + h.name
FROM sys.tables t
JOIN sys.tables h ON t.history_table_id = h.object_id
WHERE t.object_id = OBJECT_ID('dbo.customer') 
  AND t.temporal_type = 2;

IF @FullHistoryName IS NOT NULL
BEGIN
    DECLARE @Sql NVARCHAR(MAX) = N'
    SELECT @cnt = COUNT(*)
    FROM ' + QUOTENAME(@HistoryTableSchema) + N'.' + QUOTENAME(@HistoryTableName) + N'
    WHERE customer_id = 42 
       OR full_name = ''Subject_0000042'' 
       OR email = ''subject42@example.invalid'' 
       OR phone = ''+1-555-0000042'';';
    
    DECLARE @Count INT;
    EXEC sp_executesql @Sql, N'@cnt INT OUTPUT', @cnt = @Count OUTPUT;
    
    INSERT INTO @Results (object_name, rows_found)
    VALUES (@FullHistoryName, @Count);
END

-- Return the final result set
SELECT object_name, rows_found 
FROM @Results;
