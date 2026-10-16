WITH CheckResults AS (
    -- 1. Check dbo.customer itself (The original source of deletion)
    SELECT 
        'dbo.customer' AS object_name,
        COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS found_count

    UNION ALL

    -- 2. Placeholder check for other potential tables (e.g., assuming a common 'users' or 'profiles' table might exist)
    -- NOTE: Since no schema was provided beyond dbo.customer, this block assumes the existence of related, yet unknown, tables that might contain PII data.
    -- If these tables do not exist in reality, they will simply contribute 0 rows to the final result set.

    SELECT 
        'dbo.users_profiles' AS object_name, -- Example table name
        COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END)

    UNION ALL

    -- Add more checks here if the schema inspection reveals other tables (e.g., dbo.orders, dbo.billing_info)
    SELECT 
        'dbo.unknown_table_3' AS object_name, -- Example table name
        COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END)

    -- Add UNION ALL lines for every other user table that needs checking
)
SELECT 
    object_name,
    ISNULL(SUM(found_count), 0) AS rows_found
FROM 
    CheckResults
GROUP BY 
    object_name;
