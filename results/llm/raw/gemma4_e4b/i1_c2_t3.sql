DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(100) = 'Subject_0000042';
DECLARE @email NVARCHAR(100) = 'subject42@example.invalid';
DECLARE @phone NVARCHAR(50) = '+1-555-0000042';

-- Variables to store the counts for structured output
DECLARE @count_customer INT;
DECLARE @count_cdc INT;

-- 1. Check the primary operational table (dbo.customer)
SELECT @count_customer = COUNT(*)
FROM dbo.customer c
WHERE c.customer_id = @customer_id
  AND c.full_name = @full_name
  AND c.email = @email
  AND c.phone = @phone;

-- 2. Check the Change Data Capture table (cdc.dbo_customer_CT)
SELECT @count_cdc = COUNT(*)
FROM cdc.dbo_customer_CT c
WHERE c.customer_id = @customer_id
  AND c.full_name = @full_name
  AND c.email = @email
  AND c.phone = @phone;

-- Return the results in the mandated format (One result set, two columns)
SELECT 'dbo.customer' AS object_name, @count_customer AS rows_found
UNION ALL
SELECT 'cdc.dbo_customer_CT', @count_cdc;
