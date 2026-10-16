-- SCRIPT
SET NOCOUNT ON;

SELECT v.object_name, v.rows_found
FROM (
    SELECT CAST(N'dbo.customer' AS nvarchar(256)) AS object_name,
           (SELECT COUNT(*) FROM dbo.customer
             WHERE full_name = N'Subject_0000042'
                OR email = N'subject42@example.invalid'
                OR phone = N'+1-555-0000042') AS rows_found
    UNION ALL
    SELECT N'dbo.member',
           (SELECT COUNT(*) FROM dbo.member
             WHERE full_name = N'Subject_0000042'
                OR email = N'subject42@example.invalid'
                OR phone = N'+1-555-0000042')
    UNION ALL
    SELECT N'dbo.member_history',
           (SELECT COUNT(*) FROM dbo.member_history
             WHERE full_name = N'Subject_0000042'
                OR email = N'subject42@example.invalid'
                OR phone = N'+1-555-0000042')
    UNION ALL
    SELECT N'cdc.dbo_customer_CT',
           (SELECT COUNT(*) FROM cdc.dbo_customer_CT
             WHERE full_name = N'Subject_0000042'
                OR email = N'subject42@example.invalid'
                OR phone = N'+1-555-0000042')
) AS v;
