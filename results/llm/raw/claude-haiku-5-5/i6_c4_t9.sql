SET NOCOUNT ON;

SELECT object_name, rows_found
FROM (
    SELECT N'cdc.dbo_customer_CT' AS object_name,
           (SELECT COUNT(*) FROM cdc.dbo_customer_CT WHERE phone = N'+1-555-0000042') AS rows_found
    UNION ALL
    SELECT N'dbo.customer',
           (SELECT COUNT(*) FROM dbo.customer
             WHERE full_name LIKE N'%+1-555-0000042%'
                OR email LIKE N'%+1-555-0000042%')
    UNION ALL
    SELECT N'cdc.ddl_history',
           (SELECT COUNT(*) FROM cdc.ddl_history WHERE ddl_command LIKE N'%+1-555-0000042%')
) AS x;
