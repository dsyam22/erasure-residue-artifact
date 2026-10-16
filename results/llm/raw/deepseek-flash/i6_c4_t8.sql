SELECT object_name, rows_found
FROM (
    SELECT 'cdc.dbo_customer_CT' AS object_name,
           COUNT(*) AS rows_found
    FROM cdc.dbo_customer_CT
    WHERE phone = '+1-555-0000042'
       OR phone LIKE '%555-0000042%'
       OR phone LIKE '%5550000042%'
       OR phone LIKE '%+1-555-0000042%'

    UNION ALL

    SELECT 'dbo.customer',
           COUNT(*)
    FROM dbo.customer
    WHERE CAST(customer_id AS nvarchar(4000)) LIKE '%42%'
      AND (
            full_name LIKE '%Subject_0000042%'
         OR email LIKE '%subject42@example.invalid%'
      )
) AS checks
ORDER BY object_name;
