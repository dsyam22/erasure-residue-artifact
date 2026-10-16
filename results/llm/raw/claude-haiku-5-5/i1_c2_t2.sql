SET NOCOUNT ON;

SELECT r.object_name,
       r.rows_found
FROM (
    SELECT N'dbo.customer' AS object_name,
           (SELECT COUNT(*)
            FROM dbo.customer AS c
            WHERE c.customer_id = 42
               OR c.full_name = N'Subject_0000042'
               OR c.email = N'subject42@example.invalid'
               OR c.phone = N'+1-555-0000042') AS rows_found

    UNION ALL

    SELECT N'cdc.dbo_customer_CT' AS object_name,
           (SELECT COUNT(*)
            FROM cdc.dbo_customer_CT AS ct
            WHERE ct.customer_id = 42
               OR ct.full_name = N'Subject_0000042'
               OR ct.email = N'subject42@example.invalid'
               OR ct.phone = N'+1-555-0000042') AS rows_found
) AS r
ORDER BY r.object_name;
