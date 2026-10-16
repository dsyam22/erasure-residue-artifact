DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(100) = 'Subject_0000042';
DECLARE @email NVARCHAR(100) = 'subject42@example.invalid';
DECLARE @phone NVARCHAR(50) = '+1-555-0000042';

-- Count remaining data in the operational table (dbo.customer)
SELECT @count_customer = COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
  AND full_name = @full_name
  AND email = @email
  AND phone = @phone;

-- Count remaining data in the history table (dbo.customer_history)
SELECT @count_history = COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @customer_id
  AND full_name = @full_name
  AND email = @email
  AND phone = @phone;

-- Return the unified result set as required
SELECT 
    'dbo.customer' AS object_name, 
    @count_customer AS rows_found
UNION ALL
SELECT 
    'dbo.customer_history' AS object_name, 
    @count_history;
