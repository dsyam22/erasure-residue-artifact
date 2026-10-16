WITH ObjectList AS (
    -- Define all objects we are checking, including primary ones just in case triggers or auditing failed.
    SELECT 'dbo.customer' AS FullObjectName, 'customer' AS BaseName
    UNION ALL
    SELECT 'dbo.member', 'member'
    -- Add other potentially relevant tables here if they were discovered (e.g., logs, history)
),
DataChecks AS (
    -- Check dbo.customer for residual data
    SELECT 
        'dbo.customer' AS object_name,
        COUNT(CASE WHEN T1.full_name = 'Subject_0000042' AND T1.email = 'subject42@example.invalid' OR T1.phone LIKE '%+1-555-0000042%' THEN 1 END) AS rows_found
    FROM dbo.customer T1

    UNION ALL

    -- Check dbo.member for residual data
    SELECT 
        'dbo.member',
        COUNT(CASE WHEN T2.full_name = 'Subject_0000042' AND T2.email = 'subject42@example.invalid' OR T2.phone LIKE '%+1-555-0000042%' THEN 1 END) AS rows_found
    FROM dbo.member T2

    -- NOTE: If auxiliary tables (e.g., AuditLog, UserProfile) were found in the schema inspection,
    -- they would be added here following the UNION ALL pattern. 
    -- Example structure for a hypothetical table 'dbo.audit_log':
    /*
    UNION ALL
    SELECT 
        'dbo.audit_log',
        COUNT(CASE WHEN T3.full_name = 'Subject_0000042' OR T3.email = 'subject42@example.invalid' THEN 1 END) AS rows_found
    FROM dbo.audit_log T3
    */

    -- Since no other tables were provided, we only check the known objects.
)
SELECT 
    object_name,
    ISNULL(CAST(rows_found AS INT), 0) AS rows_found -- Ensure output type is clean integer count
FROM DataChecks;
