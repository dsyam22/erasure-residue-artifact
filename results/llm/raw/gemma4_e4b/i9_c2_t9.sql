WITH TargetData AS (
    -- Define the subject data points once for reusability and clarity
    SELECT 42 AS customer_id, 
           'Subject_0000042' AS full_name, 
           'subject42@example.invalid' AS email, 
           '+1-555-0000042' AS phone
),
CustomerCurrentCheck AS (
    -- Check the current live table for residual data
    SELECT 
        'dbo.customer' AS object_name,
        COUNT(c.customer_id) AS rows_found
    FROM 
        dbo.customer c
    CROSS JOIN 
        TargetData td
    WHERE 
        c.customer_id = td.customer_id
        AND c.full_name = td.full_name
        AND c.email = td.email
        AND c.phone = td.phone
),
CustomerHistoryCheck AS (
    -- Check the temporal history table for residual data
    SELECT 
        'dbo.customer_history' AS object_name,
        COUNT(h.customer_id) AS rows_found
    FROM 
        dbo.customer_history h
    CROSS JOIN 
        TargetData td
    WHERE 
        h.customer_id = td.customer_id
        AND h.full_name = td.full_name
        AND h.email = td.email
        AND h.phone = td.phone
)
-- Combine results into the required single result set format
SELECT object_name, rows_found FROM CustomerCurrentCheck
UNION ALL
SELECT object_name, rows_found FROM CustomerHistoryCheck;
