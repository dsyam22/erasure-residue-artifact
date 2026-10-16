-- Check dbo.customer for residual data matching the subject's PII
SELECT 
    'dbo.customer' AS object_name, 
    COUNT(*) AS rows_found 
FROM 
    dbo.customer 
WHERE 
    customer_id = 42 
    AND full_name = 'Subject_0000042' 
    AND email = 'subject42@example.invalid' 
    AND phone = '+1-555-0000042'

UNION ALL

-- Check dbo.customer_history for residual data matching the subject's PII (Most likely location)
SELECT 
    'dbo.customer_history' AS object_name, 
    COUNT(*) AS rows_found 
FROM 
    dbo.customer_history 
WHERE 
    customer_id = 42 
    AND full_name = 'Subject_0000042' 
    AND email = 'subject42@example.invalid' 
    AND phone = '+1-555-0000042';
