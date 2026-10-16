DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname NOT NULL, rows_found int NOT NULL);

INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

INSERT INTO #results (object_name, rows_found)
SELECT N'reporting.customer_replica',
       COUNT_BIG(*)
FROM reporting.customer_replica
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found
FROM #results;

DROP TABLE #results;
