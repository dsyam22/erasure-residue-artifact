SELECT object_name, rows_found
FROM (
    SELECT 'dbo.customer' AS object_name,
           COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE full_name = N'Subject_0000042'
       OR email = N'subject42@example.invalid'

    UNION ALL

    SELECT 'cdc.dbo_customer_CT' AS object_name,
           COUNT(*) AS rows_found
    FROM cdc.dbo_customer_CT
    WHERE phone = N'+1-555-0000042'
) AS results;
