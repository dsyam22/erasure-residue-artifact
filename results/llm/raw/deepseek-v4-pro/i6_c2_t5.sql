SET NOCOUNT ON;

DECLARE @customer_id INT = 42;
DECLARE @phone NVARCHAR(50) = '+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check current customer table (phone column dropped, so no phone data should exist)
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
  AND (CAST(full_name AS NVARCHAR(MAX)) = 'Subject_0000042')
  AND (CAST(email AS NVARCHAR(MAX)) = 'subject42@example.invalid')
  AND (1 = 0); -- phone column no longer exists, so no rows can match phone

-- Check CDC capture instance for dbo_customer (historical data may contain phone)
INSERT INTO #results (object_name, rows_found)
SELECT 'cdc.dbo_customer_CT', COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @customer_id
  AND phone = @phone;

-- Check system-versioned temporal history table if exists (not present per config, but include for completeness)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'customer_history' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'dbo.customer_history', COUNT(*)
    FROM dbo.customer_history
    WHERE customer_id = @customer_id
      AND phone = @phone;
END

-- Check any other tables that might contain phone data for this customer
-- (e.g., audit tables, backup tables, etc. — none specified, so we check only the known ones)

-- Return results
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
