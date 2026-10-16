WITH Counts AS (
    -- 1. Check Primary Table: dbo.customer
    SELECT 'dbo.customer' AS [object_name], COUNT(CASE WHEN customer_id = 42 AND full_name = N'Subject_0000042' AND email = N'subject42@example.invalid' AND phone = N'+1-555-0000042' THEN 1 END) AS rows_found
    UNION ALL

    -- 2. Check Primary Table: dbo.member (Current state)
    SELECT 'dbo.member' AS [object_name], COUNT(CASE WHEN full_name = N'Subject_0000042' AND email = N'subject42@example.invalid' THEN 1 END)
    UNION ALL

    -- 3. Check History Table: dbo.member_history (Temporal retention)
    SELECT 'dbo.member_history' AS [object_name], COUNT(CASE WHEN full_name = N'Subject_0000042' AND email = N'subject42@example.invalid' THEN 1 END)
    UNION ALL

    -- 4. Check CDC Change Tracking Table: cdc.dbo_customer_CT (Record of deletion/change)
    SELECT 'cdc.dbo_customer_CT' AS [object_name], COUNT(CASE WHEN customer_id = 42 THEN 1 END)
)
SELECT object_name, rows_found
FROM Counts;
