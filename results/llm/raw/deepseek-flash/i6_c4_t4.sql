SELECT object_name, rows_found
FROM (
    SELECT 'cdc.dbo_customer_CT' AS object_name,
           COUNT(*) AS rows_found
    FROM cdc.dbo_customer_CT
    WHERE phone = '+1-555-0000042'
) AS results
ORDER BY object_name;
