SET NOCOUNT ON;

CREATE TABLE #Results (
    object_name NVARCHAR(255),
    rows_found INT
);

DECLARE @Count INT;

-- Check dbo.customer
SELECT @Count = COUNT(*) 
FROM dbo.customer 
WHERE customer_id = 42 
   OR full_name = 'Subject_0000042' 
   OR email = 'subject42@example.invalid' 
   OR phone = '+1-555-0000042';

INSERT INTO #Results (object_name, rows_found) 
VALUES ('dbo.customer', @Count);

-- Check temporal history table if it exists
DECLARE @HistorySchema NVARCHAR(128);
DECLARE @HistoryTable NVARCHAR(128);
DECLARE @Sql NVARCHAR(MAX);

SELECT @HistorySchema = s.name, @HistoryTable = t.name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.object_id = (
    SELECT history_table_id 
    FROM sys.tables 
    WHERE object_id = OBJECT_ID('dbo.customer') 
      AND temporal_type = 2
);

IF @HistoryTable IS NOT NULL
BEGIN
    SET @Sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@HistorySchema) + N'.' + QUOTENAME(@HistoryTable) + N' 
                 WHERE customer_id = 42 
                    OR full_name = ''Subject_0000042'' 
                    OR email = ''subject42@example.invalid'' 
                    OR phone = ''+1-555-0000042'';';
    
    EXEC sp_executesql @Sql, N'@cnt INT OUTPUT', @cnt = @Count OUTPUT;
    
    INSERT INTO #Results (object_name, rows_found) 
    VALUES (@HistorySchema + '.' + @HistoryTable, @Count);
END

SELECT object_name, rows_found 
FROM #Results;

DROP TABLE #Results;
