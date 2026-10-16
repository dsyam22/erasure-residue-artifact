SET NOCOUNT ON;

DECLARE @CustomerId INT = 42;
DECLARE @FullName NVARCHAR(255) = N'Subject_0000042';
DECLARE @Email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @Phone NVARCHAR(255) = N'+1-555-0000042';

CREATE TABLE #Results (
    object_name NVARCHAR(255) NOT NULL,
    rows_found INT NOT NULL
);

-- Check main table
INSERT INTO #Results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @CustomerId
   OR full_name = @FullName
   OR email = @Email
   OR phone = @Phone;

-- Check temporal history table
INSERT INTO #Results (object_name, rows_found)
SELECT N'dbo.customer_history', COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @CustomerId
   OR full_name = @FullName
   OR email = @Email
   OR phone = @Phone;

-- Check for CDC change tables (if any exist for this table)
IF EXISTS (
    SELECT 1 
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'customer' AND s.name = 'dbo'
      AND t.is_tracked_by_cdc = 1
)
BEGIN
    DECLARE @cdcSchema NVARCHAR(255) = 'cdc';
    DECLARE @cdcTable NVARCHAR(255) = 'dbo_customer_CT';
    
    IF EXISTS (
        SELECT 1 
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.name = @cdcTable AND s.name = @cdcSchema
    )
    BEGIN
        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
            INSERT INTO #Results (object_name, rows_found)
            SELECT N''' + @cdcSchema + N'.' + @cdcTable + N''', COUNT(*)
            FROM ' + QUOTENAME(@cdcSchema) + N'.' + QUOTENAME(@cdcTable) + N'
            WHERE customer_id = @CustomerId
               OR full_name = @FullName
               OR email = @Email
               OR phone = @Phone';
        
        EXEC sp_executesql @sql, 
             N'@CustomerId INT, @FullName NVARCHAR(255), @Email NVARCHAR(255), @Phone NVARCHAR(255)',
             @CustomerId, @FullName, @Email, @Phone;
    END
END

-- Return final result set
SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;

DROP TABLE #Results;
