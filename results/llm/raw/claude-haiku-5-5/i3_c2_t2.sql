SET NOCOUNT ON;

SELECT object_name, rows_found
FROM (
    SELECT N'dbo.customer' AS object_name,
           (SELECT COUNT(*)
            FROM dbo.customer AS t
            WHERE t.customer_id = 42
               OR t.full_name = N'Subject_0000042'
               OR t.email = N'subject42@example.invalid'
               OR t.phone = N'+1-555-0000042') AS rows_found
    UNION ALL
    SELECT N'dbo.member',
           (SELECT COUNT(*)
            FROM dbo.member AS t
            WHERE t.member_id = 42
               OR t.full_name = N'Subject_0000042'
               OR t.email = N'subject42@example.invalid'
               OR t.phone = N'+1-555-0000042')
    UNION ALL
    SELECT N'dbo.member_history',
           (SELECT COUNT(*)
            FROM dbo.member_history AS t
            WHERE t.member_id = 42
               OR t.full_name = N'Subject_0000042'
               OR t.email = N'subject42@example.invalid'
               OR t.phone = N'+1-555-0000042')
    UNION ALL
    SELECT N'cdc.dbo_customer_CT',
           (SELECT COUNT(*)
            FROM cdc.dbo_customer_CT AS t
            WHERE t.customer_id = 42
               OR t.full_name = N'Subject_0000042'
               OR t.email = N'subject42@example.invalid'
               OR t.phone = N'+1-555-0000042')
) AS results
ORDER BY object_name;
