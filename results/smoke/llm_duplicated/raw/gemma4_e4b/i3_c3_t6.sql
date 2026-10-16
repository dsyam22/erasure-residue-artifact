WITH CheckCDC AS (
    -- Checking the CDC change table for dbo.customer
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        CAST(COUNT(CASE WHEN c.customer_id = 42 OR c.full_name LIKE N'%Subject%#' OR c.email LIKE N'%subject42@%' OR c.phone LIKE N'%555-0000042' THEN 1 END) AS INT) AS rows_found
    FROM
        cdc.dbo_customer_CT c
),
CheckMemberHistory AS (
    -- Checking the temporal history table for dbo.member
    SELECT
        'dbo.member_history' AS object_name,
        CAST(COUNT(CASE WHEN mh.member_id = 42 OR mh.full_name LIKE N'%Subject%#' OR mh.email LIKE N'%subject42@%' OR mh.phone LIKE N'%555-0000042' THEN 1 END) AS INT) AS rows_found
    FROM
        dbo.member_history mh
),
CheckCustomerOriginal AS (
    -- Checking the original dbo.customer table
    SELECT
        'dbo.customer' AS object_name,
        CAST(COUNT(CASE WHEN c.customer_id = 42 OR c.full_name LIKE N'%Subject%#' OR c.email LIKE N'%subject42@%' OR c.phone LIKE N'%555-0000042' THEN 1 END) AS INT) AS rows_found
    FROM
        dbo.customer c
),
CheckMemberOriginal AS (
    -- Checking the original dbo.member table
    SELECT
        'dbo.member' AS object_name,
        CAST(COUNT(CASE WHEN m.member_id = 42 OR m.full_name LIKE N'%Subject%#' OR m.email LIKE N'%subject42@%' OR m.phone LIKE N'%555-0000042' THEN 1 END) AS INT) AS rows_found
    FROM
        dbo.member m
)

-- Combine all results into a single result set
SELECT object_name, rows_found FROM CheckCDC
UNION ALL
SELECT object_name, rows_found FROM CheckMemberHistory
UNION ALL
SELECT object_name, rows_found FROM CheckCustomerOriginal
UNION ALL
SELECT object_name, rows_found FROM CheckMemberOriginal;
