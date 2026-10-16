DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = N'Subject_0000042';
DECLARE @email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @phone NVARCHAR(50) = N'+1-555-0000042';

SELECT 
    object_name,
    SUM(rows_found) AS rows_found
FROM
(
    SELECT 
        N'dbo.customer' AS object_name,
        COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone

    UNION ALL

    SELECT 
        N'reporting.customer_replica' AS object_name,
        COUNT(*) AS rows_found
    FROM reporting.customer_replica
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone
) AS checks
GROUP BY object_name;
