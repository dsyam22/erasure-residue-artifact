SET NOCOUNT ON;

SELECT x.object_name, x.rows_found
FROM (
    SELECT N'dbo.customer' AS object_name, COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE customer_id = 42
       OR full_name = N'Subject_0000042'
       OR email = N'subject42@example.invalid'
       OR phone = N'+1-555-0000042'

    UNION ALL

    SELECT N'dbo.customer_history' AS object_name, COUNT(*) AS rows_found
    FROM dbo.customer_history
    WHERE customer_id = 42
       OR full_name = N'Subject_0000042'
       OR email = N'subject42@example.invalid'
       OR phone = N'+1-555-0000042'
) AS x
ORDER BY x.object_name;
