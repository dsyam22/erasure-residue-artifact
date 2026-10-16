SELECT 'cdc.dbo_customer_CT' AS object_name,
       COUNT(*) AS rows_found
FROM cdc.dbo_customer_CT
WHERE customer_id = 42
  AND phone = '+1-555-0000042'
UNION ALL
SELECT 'cdc.ddl_history' AS object_name,
       COUNT(*) AS rows_found
FROM cdc.ddl_history
WHERE ddl_command LIKE '%phone%'
UNION ALL
SELECT 'dbo.customer' AS object_name,
       COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = 42
  AND EXISTS (
      SELECT 1
      FROM sys.columns c
      WHERE c.object_id = OBJECT_ID('dbo.customer')
        AND c.name = 'phone'
  );
