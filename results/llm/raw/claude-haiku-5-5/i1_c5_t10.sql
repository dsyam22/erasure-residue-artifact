-- SCRIPT
SET NOCOUNT ON;

SELECT x.object_name, x.rows_found
FROM (
    SELECT N'dbo.customer' AS object_name,
           (SELECT COUNT(*) FROM dbo.customer
            WHERE full_name = N'Subject_0000042'
               OR email = N'subject42@example.invalid'
               OR phone = N'+1-555-0000042') AS rows_found
    UNION ALL
    SELECT N'cdc.dbo_customer_CT',
           (SELECT COUNT(*) FROM cdc.dbo_customer_CT
            WHERE full_name = N'Subject_0000042'
               OR email = N'subject42@example.invalid'
               OR phone = N'+1-555-0000042')
    UNION ALL
    SELECT N'cdc.ddl_history',
           (SELECT COUNT(*) FROM cdc.ddl_history
            WHERE CHARINDEX(N'Subject_0000042', ddl_command) > 0
               OR CHARINDEX(N'subject42@example.invalid', ddl_command) > 0
               OR CHARINDEX(N'+1-555-0000042', ddl_command) > 0)
) AS x
ORDER BY x.object_name;
