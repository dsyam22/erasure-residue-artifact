SELECT object_name, rows_found
FROM (
    SELECT 'dbo.customer' AS object_name,
           (SELECT COUNT(*) FROM dbo.customer
            WHERE customer_id = 42
               OR full_name = N'Subject_0000042'
               OR email = N'subject42@example.invalid'
               OR phone = N'+1-555-0000042') AS rows_found
    UNION ALL
    SELECT 'dbo.member',
           (SELECT COUNT(*) FROM dbo.member
            WHERE member_id = 42
               OR full_name = N'Subject_0000042'
               OR email = N'subject42@example.invalid'
               OR phone = N'+1-555-0000042')
) AS checks;
