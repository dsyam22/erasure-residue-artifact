DECLARE @object_name NVARCHAR(128) = 'dbo.customer';
DECLARE @count INT;

-- Check dbo.customer for any record matching the subject's identifying data in scope.
SELECT 
    @count = COUNT(*) 
FROM 
    dbo.customer
WHERE 
    customer_id = 42 
    OR full_name = 'Subject_0000042' 
    OR email = 'subject42@example.invalid' 
    OR phone = '+1-555-0000042';

-- Return the required result set format
SELECT 
    @object_name AS object_name, 
    @count AS rows_found;
