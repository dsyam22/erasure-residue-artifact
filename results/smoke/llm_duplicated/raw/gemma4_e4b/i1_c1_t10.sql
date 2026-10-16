DECLARE @ObjectName NVARCHAR(128) = 'dbo.customer';
DECLARE @RowsFound INT;

-- Count the number of rows matching the subject's data in dbo.customer
SELECT @RowsFound = COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
  AND full_name = 'Subject_0000042'
  AND email = 'subject42@example.invalid'
  AND phone = '+1-555-0000042';

-- Return the required single result set structure
SELECT 
    @ObjectName AS object_name,
    @RowsFound AS rows_found;
