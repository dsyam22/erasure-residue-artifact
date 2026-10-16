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

-- Check the system-versioned history table, if it exists
DECLARE @HistorySchema NVARCHAR(128);
DECLARE @HistoryTable NVARCHAR(128);
DECLARE @HistoryFullName NVARCHAR(256);
DECLARE @SQL NVARCHAR(MAX);

SELECT @HistorySchema = s.name, @HistoryTable = h.name
FROM sys.tables t
JOIN sys.tables h ON t.history_table_id = h.object_id
JOIN sys.schemas s ON h.schema_id = s.schema_id
WHERE t.object_id = OBJECT_ID('dbo.customer');

IF @HistoryTable IS NOT NULL
BEGIN
    SET @HistoryFullName = @HistorySchema + '.' + @HistoryTable;
    SET @SQL = N'
        SELECT @cnt = COUNT(*)
        FROM ' + QUOTENAME(@HistorySchema) + '.' + QUOTENAME(@HistoryTable) + N'
        WHERE customer_id = 42 
           OR full_name = ''Subject_0000042'' 
           OR email = ''subject42@example.invalid'' 
           OR phone = ''+1-555-0000042'';';
           
    DECLARE @cnt INT;
    EXEC sp_executesql @SQL, N'@cnt INT OUTPUT', @cnt OUTPUT;
    
    INSERT INTO @Results (object_name, rows_found)
    VALUES (@HistoryFullName, @cnt);
END

SELECT object_name, rows_found 
FROM @Results;
