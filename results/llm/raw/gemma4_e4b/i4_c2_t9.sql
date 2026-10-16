WITH CheckCustomer AS (
    -- Check for original PII in the current dbo.customer table
    SELECT 
        CAST('dbo.customer' AS nvarchar) AS object_name,
        COUNT(*) AS rows_found
    FROM 
        dbo.customer
    WHERE 
        full_name = 'Subject_0000042' 
        AND email = 'subject42@example.invalid' 
        AND phone = '+1-555-0000042'
),
CheckMember AS (
    -- Check for original PII in the current dbo.member table
    SELECT 
        CAST('dbo.member' AS nvarchar) AS object_name,
        COUNT(*) AS rows_found
    FROM 
        dbo.member
    WHERE 
        full_name = 'Subject_0000042' 
        AND email = 'subject42@example.invalid' 
        AND phone = '+1-555-0000042'
),
CheckMemberHistory AS (
    -- Check for original PII in the history table (dbo.member_history)
    SELECT 
        CAST('dbo.member_history' AS nvarchar) AS object_name,
        COUNT(*) AS rows_found
    FROM 
        dbo.member_history
    WHERE 
        full_name = 'Subject_0000042' 
        AND email = 'subject42@example.invalid' 
        AND phone = '+1-555-0000042'
)
-- Combine all results into a single result set as required
SELECT * FROM CheckCustomer
UNION ALL
SELECT * FROM CheckMember
UNION ALL
SELECT * FROM CheckMemberHistory;
