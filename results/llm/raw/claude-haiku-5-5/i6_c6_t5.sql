-- SCRIPT
SELECT 'cdc.dbo_customer_CT' AS object_name,
       (SELECT COUNT(*) FROM cdc.dbo_customer_CT
         WHERE phone = N'+1-555-0000042') AS rows_found
UNION ALL
SELECT 'dbo.customer' AS object_name,
       0 AS rows_found
UNION ALL
SELECT 'cdc.ddl_history' AS object_name,
       (SELECT COUNT(*) FROM cdc.ddl_history
         WHERE ddl_command LIKE N'%555-0000042%') AS rows_found;
