SELECT object_name, rows_found
FROM (
    SELECT 'dbo.customer' AS object_name,
           COUNT_BIG(*) AS rows_found
    FROM dbo.customer
    WHERE customer_id = 42
       OR full_name = N'Subject_0000042'
       OR email = N'subject42@example.invalid'
       OR phone = N'+1-555-0000042'

    UNION ALL

    SELECT 'dbo.customer_history' AS object_name,
           COUNT_BIG(*) AS rows_found
    FROM dbo.customer_history
    WHERE customer_id = 42
       OR full_name = N'Subject_0000042'
       OR email = N'subject42@example.invalid'
       OR phone = N'+1-555-0000042'
) AS results;
