SET NOCOUNT ON;

DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = N'Subject_0000042';
DECLARE @email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check main table
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check history table (temporal)
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer_history', COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check CDC change tables (if CDC is enabled)
IF EXISTS (SELECT 1 FROM sys.change_tables WHERE source_object_id = OBJECT_ID('dbo.customer'))
BEGIN
    DECLARE @capture_instance NVARCHAR(255);
    SELECT @capture_instance = capture_instance
    FROM sys.change_tables
    WHERE source_object_id = OBJECT_ID('dbo.customer');

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
        INSERT INTO #results (object_name, rows_found)
        SELECT N''cdc.' + QUOTENAME(@capture_instance) + N'_CT'', COUNT(*)
        FROM cdc.' + QUOTENAME(@capture_instance) + N'_CT
        WHERE customer_id = @customer_id
           OR full_name = @full_name
           OR email = @email
           OR phone = @phone;
    ';
    EXEC sp_executesql @sql, N'@customer_id INT, @full_name NVARCHAR(255), @email NVARCHAR(255), @phone NVARCHAR(255)',
                       @customer_id, @full_name, @email, @phone;
END
ELSE
BEGIN
    -- If CDC is not enabled, still include a row with 0
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', 0;
END;

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
