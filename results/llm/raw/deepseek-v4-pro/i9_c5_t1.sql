-- SCRIPT
DECLARE @results TABLE (object_name NVARCHAR(255), rows_found INT);

-- Check dbo.customer for any remaining rows with the subject's original personal data
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = 'Subject_0000042'
   OR email = 'subject42@example.invalid'
   OR phone = '+1-555-0000042';

-- Return the results
SELECT object_name, rows_found
FROM @results;
