-- SCRIPT
SET NOCOUNT ON;

SELECT 'dbo.customer' AS object_name,
       (SELECT COUNT(*)
        FROM dbo.customer AS x
        WHERE x.customer_id = 42
           OR x.full_name = N'Subject_0000042'
           OR x.email = N'subject42@example.invalid'
           OR x.phone = N'+1-555-0000042') AS rows_found
UNION ALL
SELECT 'reporting.customer_replica' AS object_name,
       (SELECT COUNT(*)
        FROM reporting.customer_replica AS x
        WHERE x.customer_id = 42
           OR x.full_name = N'Subject_0000042'
           OR x.email = N'subject42@example.invalid'
           OR x.phone = N'+1-555-0000042') AS rows_found;
