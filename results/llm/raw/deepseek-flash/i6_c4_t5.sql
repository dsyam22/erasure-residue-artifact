SELECT object_name, rows_found
FROM (
    SELECT 'cdc.dbo_customer_CT' AS object_name,
           COUNT(*) AS rows_found
    FROM cdc.dbo_customer_CT
    WHERE phone = '+1-555-0000042'

    UNION ALL

    SELECT 'dbo.customer' AS object_name,
           COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE 1 = 0
) AS checks
WHERE object_name = 'cdc.dbo_customer_CT'
   OR object_name = 'dbo.customer'
ORDER BY object_name;
