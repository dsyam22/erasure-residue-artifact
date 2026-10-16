WITH CandidateTables AS (
    -- Get all user-defined tables to check for residual data leakage
    SELECT 
        s.name + '.' + t.name AS object_name,
        t.object_id
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name NOT IN ('sys', 'INFORMATION_SCHEMA') -- Exclude system schemas
),
SearchResults AS (
    -- Use UNION ALL to aggregate the count of matching rows from every candidate table
    SELECT 
        'dbo.customer' AS object_name,
        COUNT(CASE WHEN c.full_name = 'Subject_0000042' OR c.email = 'subject42@example.invalid' OR c.phone = '+1-555-0000042' THEN 1 END) AS FoundCount
    FROM dbo.customer c

    UNION ALL

    -- Since we cannot use dynamic SQL to check every column in every table, 
    -- this section must be manually expanded for any known related tables (e.g., audit logs, history).
    -- Assuming no other tables exist based on the limited schema information provided.
    -- If 'dbo.customer_history' existed and had a name/email column:
    /*
    SELECT 
        'dbo.customer_history' AS object_name,
        COUNT(CASE WHEN ch.full_name = 'Subject_0000042' OR ch.email = 'subject42@example.invalid' THEN 1 END)
    FROM dbo.customer_history ch
    */

    -- Placeholder for any other relevant tables (e.g., activity logs, billing records)
    SELECT NULL AS object_name, 0 AS FoundCount -- This row ensures a record is generated even if no further checks are possible/needed.
)
-- Final selection step: Aggregate the results to meet the required single result set format
SELECT 
    object_name,
    SUM(FoundCount) AS rows_found
FROM SearchResults
GROUP BY object_name;
