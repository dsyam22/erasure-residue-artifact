SET NOCOUNT ON;

DECLARE @Results TABLE (
    object_name NVARCHAR(255),
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

-- Check the temporal history table dynamically (if system-versioning is enabled)
DECLARE @HistoryFullName NVARCHAR(256);
DECLARE @SQL NVARCHAR(MAX);
DECLARE @Count INT;

SELECT @HistoryFullName = QUOTENAME(SCHEMA_NAME(h.schema_id)) + '.' + QUOTENAME(h.name)
FROM sys.tables t
JOIN sys.tables h ON t.history_table_id = h.object_id
WHERE t.object_id = OBJECT_ID('dbo.customer');

IF @HistoryFullName IS NOT NULL
BEGIN
    SET @SQL = N'
        SELECT @cnt = COUNT(*) 
        FROM ' + @HistoryFullName + N' 
        WHERE customer_id = 42 
           OR full_name = ''Subject_0000042'' 
           OR email = ''subject42@example.invalid'' 
           OR phone = ''+1-555-0000042'';';
           
    EXEC sp_executesql @SQL, N'@cnt INT OUTPUT', @cnt = @Count OUTPUT;
    
    INSERT INTO @Results (object_name, rows_found)
    VALUES (REPLACE(REPLACE(@HistoryFullName, '[', ''), ']', ''), @Count);
END

-- Return exactly one result set
SELECT object_name, rows_found 
FROM @Results;
