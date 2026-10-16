SET NOCOUNT ON;

SELECT x.object_name, x.rows_found
FROM (
    SELECT
        CAST(N'dbo.customer' AS nvarchar(256)) AS object_name,
        COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE customer_id = 42
       OR full_name = N'Subject_0000042'
       OR email = N'subject42@example.invalid'
       OR phone = N'+1-555-0000042'

    UNION ALL

    SELECT
        CAST(N'reporting.customer_replica' AS nvarchar(256)),
        COUNT(*)
    FROM reporting.customer_replica
    WHERE customer_id = 42
       OR full_name = N'Subject_0000042'
       OR email = N'subject42@example.invalid'
       OR phone = N'+1-555-0000042'
) AS x
ORDER BY x.object_name;
