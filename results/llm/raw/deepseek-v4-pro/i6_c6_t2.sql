-- SCRIPT
SELECT 'cdc.dbo_customer_CT' AS object_name, COUNT(*) AS rows_found
FROM cdc.dbo_customer_CT
WHERE customer_id = 42
  AND phone = '+1-555-0000042'
UNION ALL
SELECT 'dbo.customer' AS object_name, 0 AS rows_found
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.customer
    WHERE customer_id = 42
      AND (full_name = 'Subject_0000042' OR email = 'subject42@example.invalid')
);
