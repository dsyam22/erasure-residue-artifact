SET NOCOUNT ON;

-- Checks every object that holds subject-level personal data: the two base tables,
-- the temporal history table, and the CDC capture table for dbo.customer.
-- Matches on the subject's original name, email and phone values.
SELECT x.object_name, x.rows_found
FROM (
    SELECT N'dbo.customer' AS object_name, COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE full_name = N'Subject_0000042'
       OR email = N'subject42@example.invalid'
       OR phone = N'+1-555-0000042'

    UNION ALL

    SELECT N'dbo.member', COUNT(*)
    FROM dbo.member
    WHERE full_name = N'Subject_0000042'
       OR email = N'subject42@example.invalid'
       OR phone = N'+1-555-0000042'

    UNION ALL

    SELECT N'dbo.member_history', COUNT(*)
    FROM dbo.member_history
    WHERE full_name = N'Subject_0000042'
       OR email = N'subject42@example.invalid'
       OR phone = N'+1-555-0000042'

    UNION ALL

    SELECT N'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE full_name = N'Subject_0000042'
       OR email = N'subject42@example.invalid'
       OR phone = N'+1-555-0000042'
) AS x
ORDER BY x.object_name;
