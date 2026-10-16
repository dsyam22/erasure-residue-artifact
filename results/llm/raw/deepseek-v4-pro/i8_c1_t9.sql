SET NOCOUNT ON;

DECLARE @results TABLE (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check dbo.customer for any rows that still contain any of the subject's original personal data
INSERT INTO @results (object_name, rows_found)
SELECT 
    'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.customer
WHERE 
    customer_id = 42
    OR full_name = N'Subject_0000042'
    OR email = 'subject42@example.invalid'
    OR phone = '+1-555-0000042';

-- Return the final result set
SELECT object_name, rows_found
FROM @results;
