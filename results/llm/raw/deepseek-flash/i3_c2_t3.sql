SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

DECLARE @results TABLE (
    object_name sysname,
    rows_found bigint
);

INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.member', COUNT_BIG(*)
FROM dbo.member
WHERE member_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.member_history', COUNT_BIG(*)
FROM dbo.member_history
WHERE member_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

INSERT INTO @results (object_name, rows_found)
SELECT N'cdc.dbo_customer_CT', COUNT_BIG(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found
FROM @results;
