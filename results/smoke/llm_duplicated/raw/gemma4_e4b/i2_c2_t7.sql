SELECT 'dbo.customer' AS object_name, COUNT(T.*) AS rows_found
FROM dbo.customer T
WHERE T.customer_id = 42
  AND T.full_name = 'Subject_0000042'
  AND T.email = 'subject42@example.invalid'
  AND T.phone = '+1-555-0000042'

UNION ALL

SELECT 'dbo.customer_history' AS object_name, COUNT(T.*) AS rows_found
FROM dbo.customer_history T
WHERE T.customer_id = 42
  AND T.full_name = 'Subject_0000042'
  AND T.email = 'subject42@example.invalid'
  AND T.phone = '+1-555-0000042';
