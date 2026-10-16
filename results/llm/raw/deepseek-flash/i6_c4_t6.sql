SELECT object_name, rows_found
FROM (
    SELECT 'dbo.customer' AS object_name,
           COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE phone = '+1-555-0000042'
) AS checks;
