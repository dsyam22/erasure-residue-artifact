-- SCRIPT
SET NOCOUNT ON;

DECLARE @results TABLE (
    object_name nvarchar(257),
    rows_found int
);

-- Check dbo.customer
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

-- Check CDC change table dbo_customer_CT
INSERT INTO @results (object_name, rows_found)
SELECT 'cdc.dbo_customer_CT', COUNT(*)
FROM cdc.dbo_customer_CT
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

-- Check other user tables that might contain the data (only dbo.customer exists, but we include all for completeness)
-- Since only dbo.customer is a user table, we don't need to check others, but we include a row for cdc tables checked.

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
