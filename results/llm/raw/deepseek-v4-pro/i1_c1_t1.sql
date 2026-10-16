DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = 'Subject_0000042';
DECLARE @email nvarchar(255) = 'subject42@example.invalid';
DECLARE @phone nvarchar(255) = '+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255),
    rows_found int
);

INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
