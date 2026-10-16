SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(100) = N'Subject_0000042';
DECLARE @email nvarchar(100) = N'subject42@example.invalid';
DECLARE @phone nvarchar(100) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found int);

INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member_history', COUNT(*)
FROM dbo.member_history
WHERE member_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

INSERT INTO #results (object_name, rows_found)
SELECT 'cdc.dbo_customer_CT', COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
