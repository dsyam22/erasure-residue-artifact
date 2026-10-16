SET NOCOUNT ON;
DECLARE @Results TABLE (object_name NVARCHAR(255), rows_found INT);

-- Check dbo.customer
INSERT INTO @Results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = 42 
   OR full_name = 'Subject_0000042' 
   OR email = 'subject42@example.invalid' 
   OR phone = '+1-555-0000042';

-- Check dbo.member
INSERT INTO @Results (object_name, rows_found)
SELECT 'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = 42 
   OR full_name = 'Subject_0000042' 
   OR email = 'subject42@example.invalid' 
   OR phone = '+1-555-0000042';

-- Check if dbo.member is a system-versioned temporal table and check its history table
DECLARE @HistoryTableId INT;
SELECT @HistoryTableId = history_table_id 
FROM sys.tables 
WHERE object_id = OBJECT_ID('dbo.member') AND temporal_type = 2;

IF @HistoryTableId IS NOT NULL
BEGIN
    DECLARE @HistorySchema NVARCHAR(128) = OBJECT_SCHEMA_NAME(@HistoryTableId);
    DECLARE @HistoryName NVARCHAR(128) = OBJECT_NAME(@HistoryTableId);
    DECLARE @FullName NVARCHAR(260) = @HistorySchema + '.' + @HistoryName;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Count INT;

    SET @SQL = N'SELECT @Count = COUNT(*) FROM ' + QUOTENAME(@HistorySchema) + '.' + QUOTENAME(@HistoryName) + 
               N' WHERE member_id = 42 OR full_name = ''Subject_0000042'' OR email = ''subject42@example.invalid'' OR phone = ''+1-555-0000042'';';
    
    EXEC sp_executesql @SQL, N'@Count INT OUTPUT', @Count OUTPUT;

    INSERT INTO @Results (object_name, rows_found)
    VALUES (@FullName, @Count);
END

SELECT object_name, rows_found
FROM @Results;
