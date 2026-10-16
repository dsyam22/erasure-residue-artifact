SET NOCOUNT ON;

SELECT v.object_name, v.rows_found
FROM (
    SELECT
        CAST(N'dbo.customer' AS nvarchar(256)) AS object_name,
        (SELECT COUNT(*)
         FROM dbo.customer AS x
         WHERE x.customer_id = 42
            OR x.full_name = N'Subject_0000042'
            OR x.email = N'subject42@example.invalid'
            OR x.phone = N'+1-555-0000042') AS rows_found
    UNION ALL
    SELECT
        CAST(N'dbo.customer_history' AS nvarchar(256)),
        (SELECT COUNT(*)
         FROM dbo.customer_history AS x
         WHERE x.customer_id = 42
            OR x.full_name = N'Subject_0000042'
            OR x.email = N'subject42@example.invalid'
            OR x.phone = N'+1-555-0000042')
) AS v
ORDER BY v.object_name;
