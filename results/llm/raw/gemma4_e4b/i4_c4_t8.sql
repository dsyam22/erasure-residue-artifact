-- Declare variables to hold the target data subject's original PII values
DECLARE @TargetFullName NVARCHAR(100) = 'Subject_0000042';
DECLARE @TargetEmail NVARCHAR(100) = 'subject42@example.invalid';
DECLARE @TargetPhone NVARCHAR(50) = '+1-555-0000042';

-- The following CTEs check for the existence of any original PII data point 
-- in the specified tables/columns. We use UNION ALL to combine results 
-- into a single result set with the required two columns.

SELECT 
    'dbo.customer' AS object_name, 
    CAST(COUNT(CASE WHEN c.full_name = @TargetFullName OR c.email = @TargetEmail OR c.phone = @TargetPhone THEN 1 END) AS INT) AS rows_found

UNION ALL

SELECT 
    'dbo.member' AS object_name, 
    CAST(COUNT(CASE WHEN m.full_name = @TargetFullName OR m.email = @TargetEmail OR m.phone = @TargetPhone THEN 1 END) AS INT) AS rows_found

UNION ALL

-- Checking the visible history table identified in schema inspection
SELECT 
    'dbo.member_history' AS object_name, 
    CAST(COUNT(CASE WHEN mh.full_name = @TargetFullName OR mh.email = @TargetEmail OR mh.phone = @TargetPhone THEN 1 END) AS INT) AS rows_found

UNION ALL

-- Include other potential tables from the output if they are confirmed to hold PII data,
-- but based on the explicit erasure scope (customer/member), we only query these three.
SELECT 'N/A' AS object_name, 0 AS rows_found; -- Ensures a final row structure is maintained if needed, though usually unnecessary with UNION ALL grouping by table name.
