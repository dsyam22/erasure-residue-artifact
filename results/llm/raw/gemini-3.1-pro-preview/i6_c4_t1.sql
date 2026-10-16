SELECT 
    'cdc.dbo_customer_CT' AS object_name, 
    COUNT(*) AS rows_found 
FROM cdc.dbo_customer_CT 
WHERE customer_id = 42 AND phone = '+1-555-0000042';
