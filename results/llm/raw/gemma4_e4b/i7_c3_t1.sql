WITH CheckResults AS (
    -- Check primary customer table
    SELECT
        N'dbo.customer' AS object_name,
        COUNT(CASE WHEN T1.full_name = 'Subject_0000042' AND T1.email = 'subject42@example.invalid' AND T1.phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM
        dbo.customer AS T1
    WHERE
        T1.customer_id = 42

    UNION ALL

    -- Check reporting replica table (downstream copy)
    SELECT
        N'reporting.customer_replica' AS object_name,
        COUNT(CASE WHEN T2.full_name = 'Subject_0000042' AND T2.email = 'subject42@example.invalid' AND T2.phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM
        reporting.customer_replica AS T2
    WHERE
        T2.customer_id = 42
)
SELECT
    object_name,
    rows_found
FROM
    CheckResults;
