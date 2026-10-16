SET NOCOUNT ON;

DECLARE @SchemaName sysname = N'dbo';
DECLARE @TableName sysname = N'customer';
DECLARE @FullObjectName nvarchar(257) = @SchemaName + N'.' + @TableName;

DECLARE @CustomerId int = 42;
DECLARE @FullName nvarchar(255) = N'Subject_0000042';
DECLARE @Email nvarchar(255) = N'subject42@example.invalid';
DECLARE @Phone nvarchar(255) = N'+1-555-0000042';

DECLARE @Results TABLE (
    object_name nvarchar(257) NOT NULL,
    rows_found int NOT NULL
);

-- Check the customer table for any rows matching any of the subject's original personal data
INSERT INTO @Results (object_name, rows_found)
SELECT
    @FullObjectName,
    COUNT(*)
FROM dbo.customer
WHERE customer_id = @CustomerId
   OR full_name = @FullName
   OR email = @Email
   OR phone = @Phone;

-- Return the results
SELECT object_name, rows_found
FROM @Results;
