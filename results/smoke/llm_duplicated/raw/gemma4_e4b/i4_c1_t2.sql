WITH CustomerCheck AS (
    -- Check dbo.customer for original data leakage associated with customer_id 42
    SELECT
        'dbo.customer' AS object_name,
        CAST(COUNT(1) AS INT) AS rows_found
    FROM
        dbo.customer
    WHERE
        customer_id = 42
        AND (
            full_name = 'Subject_0000042' OR
            email = 'subject42@example.invalid' OR
            phone = '+1-555-0000042'
        )
),
MemberCheck AS (
    -- Check dbo.member for original data leakage associated with member_id 42
    SELECT
        'dbo.member' AS object_name,
        CAST(COUNT(1) AS INT) AS rows_found
    FROM
        dbo.member
    WHERE
        member_id = 42
        AND (
            full_name = 'Subject_0000042' OR
            email = 'subject42@example.invalid' OR
            phone = '+1-555-0000042'
        )
)
-- Combine the results into a single required result set
SELECT object_name, rows_found FROM CustomerCheck
UNION ALL
SELECT object_name, rows_found FROM MemberCheck;
