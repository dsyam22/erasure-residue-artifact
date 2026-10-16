SET NOCOUNT ON;

DECLARE @Results TABLE (
    object_name NVARCHAR(256),
    rows_found INT
);

-- Check dbo.customer
INSERT INTO @Results (object_name, rows_found)
SELECT 
    'dbo.customer', 
    COUNT(*)
FROM dbo.customer
WHERE full_name = 'Subject_0000042' 
   OR email = 'subject42@example.invalid' 
   OR phone = '+1-555-0000042';

-- Check dbo.member
INSERT INTO @Results (object_name, rows_found)
SELECT 
    'dbo.member', 
    COUNT(*)
FROM dbo.member
WHERE full_name = 'Subject_0000042' 
   OR email = 'subject42@example.invalid' 
   OR phone = '+1-555-0000042';

-- Check temporal history table for dbo.member if it exists
DECLARE @HistoryTableName NVARCHAR(256);
DECLARE @HistorySQL NVARCHAR(MAX);

SELECT @HistoryTableName = QUOTENAME(SCHEMA_NAME(h.schema_id)) + '.' + QUOTENAME(h.name)
FROM sys.tables t
JOIN sys.tables h ON t.history_table_id = h.object_id
WHERE t.object_id = OBJECT_ID('dbo.member') AND t.temporal_type = 2;

IF @HistoryTableName IS NOT NULL
BEGIN
    SET @HistorySQL = N'
        SELECT 
            ''' + REPLACE(@HistoryTableName, '"', '') + ''', 
            COUNT(*) 
        FROM ' + @HistoryTableName + '
        WHERE full_name = ''Subject_0000042'' 
           OR email = ''subject42@example.invalid'' 
           OR phone = ''+1-555-0000042'';';
           
    INSERT INTO @Results (object_name, rows_found)
    EXEC sp_executesql @HistorySQL;
END

-- Return the final result set
SELECT object_name, rows_found
FROM @Results;
