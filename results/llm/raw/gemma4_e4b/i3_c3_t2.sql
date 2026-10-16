WITH Check_Customers AS (
    SELECT
        'dbo.customer' AS object_name,
        CAST(COUNT(CASE WHEN customer_id = 42 THEN 1 END) AS INT) AS rows_found
    FROM dbo.customer
),
Check_Members AS (
    SELECT
        'dbo.member' AS object_name,
        CAST(COUNT(CASE WHEN member_id = 42 THEN 1 END) AS INT) AS rows_found
    FROM dbo.member
),
Check_CDC AS (
    -- Checking the CDC Change Table for residual presence of the ID/Data
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        CAST(COUNT(CASE WHEN customer_id = 42 THEN 1 END) AS INT) AS rows_found
    FROM cdc.dbo_customer_CT
),
Check_MemberHistory AS (
    -- Checking the Temporal History table for residual presence of the ID/Data
    SELECT
        'dbo.member_history' AS object_name,
        CAST(COUNT(CASE WHEN member_id = 42 THEN 1 END) AS INT) AS rows_found
    FROM dbo.member_history
),
Check_CustomerCDC AS (
    -- Although the schema indicates CDC is enabled on dbo.customer, we must check if any records exist in the source table itself that were not covered by the dedicated change capture instance check above.
    SELECT
        'dbo.customer' AS object_name, -- Rechecking for completeness, though technically redundant due to the explicit CTE above
        CAST(COUNT(CASE WHEN customer_id = 42 THEN 1 END) AS INT) AS rows_found
    FROM dbo.customer
),
Check_MemberCDC AS (
     -- No dedicated CDC table was listed for dbo.member, but if one existed, we would check it here. Leaving this blank as per provided schema information.
    SELECT
        'N/A - dbo.member CDC' AS object_name, 
        0 AS rows_found
)
SELECT
    object_name,
    rows_found
FROM (
    -- Use UNION ALL to stack the results from all checks into a single result set.
    SELECT object_name, rows_found FROM Check_Customers
    UNION ALL
    SELECT object_name, rows_found FROM Check_Members
    UNION ALL
    SELECT object_name, rows_found FROM Check_CDC
    UNION ALL
    SELECT object_name, rows_found FROM Check_MemberHistory
) AS FinalCheck
ORDER BY 
    CASE WHEN object_name = 'dbo.customer' THEN 1 END,
    CASE WHEN object_name = 'cdc.dbo_customer_CT' THEN 2 END,
    CASE WHEN object_name = 'dbo.member' THEN 3 END,
    CASE WHEN object_name = 'dbo.member_history' THEN 4 END;
