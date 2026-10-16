-- SCRIPT
SET NOCOUNT ON;

SELECT x.object_name, x.rows_found
FROM (
    SELECT CAST(N'dbo.customer' AS nvarchar(256)) AS object_name,
           (SELECT COUNT(*) FROM dbo.customer
            WHERE full_name = N'Subject_0000042'
               OR email = N'subject42@example.invalid'
               OR phone = N'+1-555-0000042') AS rows_found
    UNION ALL
    SELECT CAST(N'dbo.member' AS nvarchar(256)),
           (SELECT COUNT(*) FROM dbo.member
            WHERE full_name = N'Subject_0000042'
               OR email = N'subject42@example.invalid'
               OR phone = N'+1-555-0000042')
    UNION ALL
    SELECT CAST(N'dbo.member_history' AS nvarchar(256)),
           (SELECT COUNT(*) FROM dbo.member_history
            WHERE full_name = N'Subject_0000042'
               OR email = N'subject42@example.invalid'
               OR phone = N'+1-555-0000042')
    UNION ALL
    SELECT CAST(N'cdc.dbo_customer_CT' AS nvarchar(256)),
           (SELECT COUNT(*) FROM cdc.dbo_customer_CT
            WHERE full_name = N'Subject_0000042'
               OR email = N'subject42@example.invalid'
               OR phone = N'+1-555-0000042')
) AS x
ORDER BY x.object_name;
