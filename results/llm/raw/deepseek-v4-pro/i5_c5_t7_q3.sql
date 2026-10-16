-- QUERY
SELECT 
    OBJECT_SCHEMA_NAME(object_id) + '.' + OBJECT_NAME(object_id) AS object_name,
    COUNT(*) AS rows_found
FROM (
    SELECT object_id, customer_id, full_name, email, phone FROM dbo.customer
    UNION ALL
    SELECT object_id, customer_id, full_name, email, phone FROM dbo.customer_history
) AS combined
WHERE 
    customer_id = 42
    OR full_name = 'Subject_0000042'
    OR email = 'subject42@example.invalid'
    OR phone = '+1-555-0000042'
GROUP BY OBJECT_SCHEMA_NAME(object_id) + '.' + OBJECT_NAME(object_id);
