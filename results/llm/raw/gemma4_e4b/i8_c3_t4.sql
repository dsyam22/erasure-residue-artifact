WITH DataSubject AS (
    SELECT
        42 AS customer_id,
        N'Subject_0000042' AS full_name,
        N'subject42@example.invalid' AS email,
        N'+1-555-0000042' AS phone
),
CheckResults AS (
    -- Check 1: The primary table where the deletion occurred
    SELECT
        CAST('dbo.customer' AS NVARCHAR(128)) AS object_name,
        COUNT(c.*) AS rows_found
    FROM dbo.customer c
    CROSS JOIN DataSubject ds
    WHERE c.customer_id = ds.customer_id
       OR c.full_name = ds.full_name
       OR c.email = ds.email
       OR c.phone = ds.phone
)
SELECT object_name, rows_found FROM CheckResults;
