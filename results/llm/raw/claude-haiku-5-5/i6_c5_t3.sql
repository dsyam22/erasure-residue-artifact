-- SCRIPT
SELECT object_name, rows_found
FROM (
    SELECT 'dbo.customer' AS object_name,
           (SELECT COUNT(*) FROM dbo.customer c
             WHERE c.customer_id = 42
               AND (c.full_name LIKE N'%+1-555-0000042%' OR c.email LIKE N'%+1-555-0000042%')) AS rows_found
    UNION ALL
    SELECT 'cdc.dbo_customer_CT',
           (SELECT COUNT(*) FROM cdc.dbo_customer_CT ct
             WHERE ct.customer_id = 42
               AND ct.phone = N'+1-555-0000042')
    UNION ALL
    SELECT 'cdc.ddl_history',
           (SELECT COUNT(*) FROM cdc.ddl_history dh
             WHERE dh.ddl_command LIKE N'%+1-555-0000042%')
) AS checks
ORDER BY object_name;
