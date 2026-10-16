DECLARE @CustomerId INT = 42;
DECLARE @FullName NVARCHAR(255) = N'Subject_0000042';
DECLARE @Email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @Phone NVARCHAR(255) = N'+1-555-0000042';

CREATE TABLE #Results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check current table
INSERT INTO #Results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = @CustomerId
   OR full_name = @FullName
   OR email = @Email
   OR phone = @Phone;

-- Check temporal history table
INSERT INTO #Results (object_name, rows_found)
SELECT 
    N'dbo.customer_history',
    COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @CustomerId
   OR full_name = @FullName
   OR email = @Email
   OR phone = @Phone;

-- Check change data capture (CDC) change tables if they exist
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'customer' AND is_tracked_by_cdc = 1)
BEGIN
    DECLARE @CaptureInstance NVARCHAR(255) = N'dbo_customer';
    IF EXISTS (SELECT 1 FROM cdc.change_tables WHERE capture_instance = @CaptureInstance)
    BEGIN
        DECLARE @Sql NVARCHAR(MAX);
        SET @Sql = N'
            INSERT INTO #Results (object_name, rows_found)
            SELECT 
                N''cdc.' + QUOTENAME(@CaptureInstance) + N'_CT'',
                COUNT(*)
            FROM cdc.' + QUOTENAME(@CaptureInstance) + N'_CT
            WHERE customer_id = @CustomerId
               OR full_name = @FullName
               OR email = @Email
               OR phone = @Phone';
        EXEC sp_executesql @Sql, N'@CustomerId INT, @FullName NVARCHAR(255), @Email NVARCHAR(255), @Phone NVARCHAR(255)', @CustomerId, @FullName, @Email, @Phone;
    END
END

-- Return final result set
SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;

DROP TABLE #Results;
