SELECT
    'dbo.customer' AS object_name,
    COUNT(CASE WHEN T.full_name = N'Subject_0000042' OR T.customer_id = 42 THEN 1 END) AS rows_found
FROM
    dbo.customer T;
