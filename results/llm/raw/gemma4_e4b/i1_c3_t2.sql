DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(100) = 'Subject_0000042';
DECLARE @email NVARCHAR(100) = 'subject42@example.invalid';
DECLARE @phone NVARCHAR(50) = '+1-555-0000042';

-- Check 1: CDC Change Tracking Table (cdc.dbo_customer_CT)
SELECT
    'cdc.dbo_customer_CT' AS object_name,
    COUNT(*) AS rows_found
FROM
    cdc.dbo_customer_CT
WHERE
    customer_id = @customer_id
    AND full_name = @full_name
    AND email = @email
    AND phone = @phone

UNION ALL

-- Check 2: Main Table (dbo.customer) - Checking for remnants/orphaned data
SELECT
    'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM
    dbo.customer
WHERE
    customer_id = @customer_id
    AND full_name = @full_name
    AND email = @email
    AND phone = @phone;
