WITH AllTables AS (
    -- Select all user-defined tables that might contain PII data
    SELECT name, OBJECT_SCHEMA + '.' + name AS object_name
    FROM sys.tables st
    JOIN sys.schemas s ON st.schema_id = s.schema_id
    WHERE s.name = 'dbo'
),
-- CTE to check for matches in the primary customer table (should be empty)
CustomerCheck AS (
    SELECT 
        CAST('dbo.customer' AS NVARCHAR(256)) AS object_name,
        COUNT(CASE WHEN T1.full_name = 'Subject_0000042' OR T1.email = 'subject42@example.invalid' OR T1.phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM dbo.customer T1
),
-- CTE to check other potential tables (Placeholder structure - adjust logic if other schemas/tables are found in subsequent steps)
OtherChecks AS (
    SELECT 
        CAST('dbo.other_user_data' AS NVARCHAR(256)) AS object_name, -- Replace with actual table names found during inspection if necessary
        COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM dbo.other_user_data -- Assuming this table exists or needs checking
    UNION ALL
    -- Add more UNION ALL blocks here for every other relevant table found (e.g., 'dbo.orders', 'dbo.profile')
    SELECT 
        CAST('N/A' AS NVARCHAR(256)), -- Use appropriate object name
        0 -- Default count if no data is available or the check fails
)
-- Final result set combining checks
SELECT
    object_name,
    ISNULL(rows_found, 0) AS rows_found
FROM CustomerCheck

UNION ALL

SELECT
    object_name,
    rows_found
FROM OtherChecks;
