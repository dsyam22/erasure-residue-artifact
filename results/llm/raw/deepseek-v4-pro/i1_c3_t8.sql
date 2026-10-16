DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = N'Subject_0000042';
DECLARE @email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check base table
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check CDC change table
INSERT INTO #results (object_name, rows_found)
SELECT N'cdc.dbo_customer_CT', COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check temporal history table (if exists)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'customer' AND temporal_type = 2)
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer_history', COUNT(*)
    FROM dbo.customer_history
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer_history', 0;
END;

-- Check any other user tables that might contain copies of the data
-- (example: audit tables, backup tables, etc.)
IF OBJECT_ID('dbo.customer_audit', 'U') IS NOT NULL
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer_audit', COUNT(*)
    FROM dbo.customer_audit
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer_audit', 0;
END;

IF OBJECT_ID('dbo.customer_backup', 'U') IS NOT NULL
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer_backup', COUNT(*)
    FROM dbo.customer_backup
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer_backup', 0;
END;

-- Return final result
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
