SELECT t.object_name, t.rows_found
FROM (
    SELECT N'dbo.customer' AS object_name,
           (SELECT COUNT(*)
              FROM dbo.customer AS c
             WHERE c.full_name = N'Subject_0000042'
                OR c.email     = N'subject42@example.invalid'
                OR c.phone     = N'+1-555-0000042') AS rows_found
    UNION ALL
    SELECT N'dbo.member',
           (SELECT COUNT(*)
              FROM dbo.member AS m
             WHERE m.full_name = N'Subject_0000042'
                OR m.email     = N'subject42@example.invalid'
                OR m.phone     = N'+1-555-0000042')
    UNION ALL
    SELECT N'dbo.member_history',
           (SELECT COUNT(*)
              FROM dbo.member_history AS mh
             WHERE mh.full_name = N'Subject_0000042'
                OR mh.email     = N'subject42@example.invalid'
                OR mh.phone     = N'+1-555-0000042')
    UNION ALL
    SELECT N'cdc.dbo_customer_CT',
           (SELECT COUNT(*)
              FROM cdc.dbo_customer_CT AS ct
             WHERE ct.full_name = N'Subject_0000042'
                OR ct.email     = N'subject42@example.invalid'
                OR ct.phone     = N'+1-555-0000042')
) AS t
ORDER BY t.object_name;
