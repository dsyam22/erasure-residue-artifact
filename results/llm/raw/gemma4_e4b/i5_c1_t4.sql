DECLARE @TargetCustomerName NVARCHAR(255) = 'Subject_0000042';
DECLARE @TargetEmail NVARCHAR(255) = 'subject42@example.invalid';
DECLARE @TargetPhone NVARCHAR(50) = '+1-555-0000042';

-- Use a single SELECT statement structure to ensure exactly one result set, 
-- checking the count for each object specified in the requirements (in this case, only dbo.customer).
SELECT 
    'dbo.customer' AS object_name, 
    (
        SELECT COUNT(*) 
        FROM dbo.customer c
        WHERE c.full_name = @TargetCustomerName OR 
              c.email = @TargetEmail OR 
              c.phone = @TargetPhone
    ) AS rows_found;
