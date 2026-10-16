SELECT 
    'dbo.customer' AS object_name, 
    (SELECT COUNT(*) FROM dbo.customer WHERE customer_id = 42 AND full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042') AS rows_found

UNION ALL

SELECT 
    'cdc.dbo_customer_CT', 
    (SELECT COUNT(*) FROM cdc.dbo_customer_CT WHERE customer_id = 42)
