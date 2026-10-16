DECLARE @TableName sysname = 'dbo.customer';
DECLARE @RowsFound INT;

-- Calculate the number of records still containing the subject's personal data
SELECT @RowsFound = COUNT(*)
FROM dbo.customer
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

-- Return the result set in the required format
SELECT 
    CAST(@TableName AS NVARCHAR(256)) AS object_name, 
    @RowsFound AS rows_found;
