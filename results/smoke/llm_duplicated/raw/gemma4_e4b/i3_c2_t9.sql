DECLARE @Full_Name NVARCHAR(255) = 'Subject_0000042';
DECLARE @Email NVARCHAR(255) = 'subject42@example.invalid';
DECLARE @Phone NVARCHAR(50) = '+1-555-0000042';

-- Use a CTE structure to calculate the count for each object and ensure exactly one result set is returned.
WITH ObjectChecks (object_name, rows_found) AS (
    -- 1. Check dbo.customer table
    SELECT 'dbo.customer' AS object_name, COUNT(1) AS rows_found FROM dbo.customer c WHERE 
        c.full_name = @Full_Name AND c.email = @Email AND c.phone = @Phone

    UNION ALL

    -- 2. Check dbo.member table (Current state)
    SELECT 'dbo.member' AS object_name, COUNT(1) AS rows_found FROM dbo.member m WHERE 
        m.full_name = @Full_Name AND m.email = @Email AND m.phone = @Phone

    UNION ALL

    -- 3. Check dbo.member_history table (Temporal History retention)
    SELECT 'dbo.member_history' AS object_name, COUNT(1) AS rows_found FROM dbo.member_history mh WHERE 
        mh.full_name = @Full_Name AND mh.email = @Email AND mh.phone = @Phone

    UNION ALL

    -- 4. Check cdc source/shadow copy (dbo.customer_CT is a change tracking table, but we check the original structure for completeness if it held PII)
    SELECT 'cdc.dbo_customer_CT' AS object_name, COUNT(1) AS rows_found FROM cdc.dbo_customer_CT ct WHERE 
        ct.full_name = @Full_Name AND ct.email = @Email AND ct.phone = @Phone
)
-- Select the final result set from the CTE
SELECT object_name, rows_found FROM ObjectChecks;
