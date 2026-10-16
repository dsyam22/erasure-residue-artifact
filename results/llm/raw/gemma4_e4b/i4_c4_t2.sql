WITH CustomerCheck AS (
    SELECT
        'dbo.customer' AS [object_name],
        COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM
        dbo.customer
),
MemberCheck AS (
    SELECT
        'dbo.member' AS [object_name],
        COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS rows_found
    FROM
        dbo.member
)
-- Combine the results into a single result set, ensuring both tables are represented
SELECT [object_name], rows_found FROM CustomerCheck
UNION ALL
SELECT [object_name], rows_found FROM MemberCheck;
