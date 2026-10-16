SELECT
    'dbo.customer' AS object_name,
    ISNULL(T1.rows_found, 0) AS rows_found
FROM
(
    SELECT COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042'
) AS T1

UNION ALL

SELECT
    'dbo.member' AS object_name,
    ISNULL(T2.rows_found, 0) AS rows_found
FROM
(
    SELECT COUNT(*) AS rows_found
    FROM dbo.member
    WHERE full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042'
) AS T2;
