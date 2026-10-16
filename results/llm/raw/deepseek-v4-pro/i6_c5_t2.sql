-- SCRIPT
DECLARE @customer_id int = 42;
DECLARE @phone nvarchar(50) = '+1-555-0000042';

SELECT 
    'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = @customer_id
  AND EXISTS (
      SELECT 1
      FROM sys.columns c
      WHERE c.object_id = OBJECT_ID('dbo.customer')
        AND c.name = 'phone'
  )
  AND EXISTS (
      SELECT 1
      FROM sys.columns c
      WHERE c.object_id = OBJECT_ID('dbo.customer')
        AND c.name = 'phone'
        AND EXISTS (
            SELECT 1
            FROM dbo.customer cust
            WHERE cust.customer_id = @customer_id
              AND cust.phone = @phone
        )
  );
