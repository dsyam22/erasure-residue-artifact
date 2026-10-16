SET NOCOUNT ON;

DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = N'Subject_0000042';
DECLARE @email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = N'+1-555-0000042';

DECLARE @results TABLE (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check dbo.customer
INSERT INTO @results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check dbo.member (current rows in temporal table)
INSERT INTO @results (object_name, rows_found)
SELECT 
    N'dbo.member',
    COUNT(*)
FROM dbo.member
WHERE member_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check dbo.member_history (history table)
INSERT INTO @results (object_name, rows_found)
SELECT 
    N'dbo.member_history',
    COUNT(*)
FROM dbo.member_history
WHERE member_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check CDC capture instance for dbo.customer
INSERT INTO @results (object_name, rows_found)
SELECT 
    N'cdc.dbo_customer_CT',
    COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
