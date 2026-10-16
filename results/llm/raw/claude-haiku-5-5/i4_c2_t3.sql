/*
  Verifies whether the erased personal data of subject customer_id 42 remains
  in this database. Read-only: SELECT statements only.
  Matches the original full_name, email, and phone values in each object that
  stores them, including the temporal history table and the CDC change table.
*/
SELECT
    v.object_name,
    v.rows_found
FROM (
    SELECT 'dbo.customer' AS object_name,
           (SELECT COUNT(*) FROM dbo.customer AS t
             WHERE t.full_name = N'Subject_0000042'
                OR t.email     = N'subject42@example.invalid'
                OR t.phone     = N'+1-555-0000042') AS rows_found
    UNION ALL
    SELECT 'dbo.member',
           (SELECT COUNT(*) FROM dbo.member AS t
             WHERE t.full_name = N'Subject_0000042'
                OR t.email     = N'subject42@example.invalid'
                OR t.phone     = N'+1-555-0000042')
    UNION ALL
    SELECT 'dbo.member_history',
           (SELECT COUNT(*) FROM dbo.member_history AS t
             WHERE t.full_name = N'Subject_0000042'
                OR t.email     = N'subject42@example.invalid'
                OR t.phone     = N'+1-555-0000042')
    UNION ALL
    SELECT 'cdc.dbo_customer_CT',
           (SELECT COUNT(*) FROM cdc.dbo_customer_CT AS t
             WHERE t.full_name = N'Subject_0000042'
                OR t.email     = N'subject42@example.invalid'
                OR t.phone     = N'+1-555-0000042')
) AS v
ORDER BY v.object_name;
