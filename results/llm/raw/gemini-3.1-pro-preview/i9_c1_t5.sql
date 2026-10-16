SET NOCOUNT ON;

DECLARE @Results TABLE (
    object_name NVARCHAR(512),
    rows_found INT
);

-- Check main table
INSERT INTO @Results (object_name, rows_found)
SELECT 
    'dbo.customer', 
    COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = 'Subject_0000042'
   OR email = 'subject42@example.invalid'
   OR phone = '+1-555-0000042';

-- Check history table if dbo.customer is a system-versioned temporal table
DECLARE @HistoryTableSchema NVARCHAR(256);
DECLARE @HistoryTableName NVARCHAR(256);
DECLARE @FullHistoryTableName NVARCHAR(512);

SELECT 
    @HistoryTableSchema = OBJECT_SCHEMA_NAME(history_table_id),
    @HistoryTableName = OBJECT_NAME(history_table_id)
FROM sys.tables
WHERE object_id = OBJECT_ID('dbo.customer')
  AND temporal_type = 2; -- SYSTEM_VERSIONED_TEMPORAL_TABLE

IF @HistoryTableName IS NOT NULL
BEGIN
    SET @FullHistoryTableName = QUOTENAME(@HistoryTableSchema) + '.' + QUOTENAME(@HistoryTableName);
    
    DECLARE @Count INT;
    DECLARE @Sql NVARCHAR(MAX) = N'
        SELECT @Count = COUNT(*) 
        FROM ' + @FullHistoryTableName + N'
        WHERE customer_id = 42
           OR full_name = ''Subject_0000042''
           OR email = ''subject42@example.invalid''
           OR phone = ''+1-555-0000042'';
    ';
    
    EXEC sp_executesql @Sql, N'@Count INT OUTPUT', @Count OUTPUT;
    
    INSERT INTO @Results (object_name, rows_found)
    VALUES (@HistoryTableSchema + '.' + @HistoryTableName, @Count);
END

SELECT object_name, rows_found
FROM @Results;
