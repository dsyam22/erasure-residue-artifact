DECLARE @TableName sysname = 'dbo.customer';
DECLARE @Count int;

-- Check for remaining data in the identified table using any of the personal identifiers
SELECT @Count = COUNT(*) 
FROM dbo.customer
WHERE full_name = 'Subject_0000042'
   OR email = 'subject42@example.invalid'
   OR phone = '+1-555-0000042';

-- Return the result in the required single format
SELECT 
    QUOTENAME(SCHEMA_NAME(object_id)) + '.' + QUOTENAME(@TableName) AS object_name,
    @Count AS rows_found;
