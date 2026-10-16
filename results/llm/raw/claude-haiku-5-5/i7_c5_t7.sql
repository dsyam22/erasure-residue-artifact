-- SCRIPT
SET NOCOUNT ON;

SELECT v.object_name, v.rows_found
FROM (
    SELECT CAST('dbo.customer' AS nvarchar(256)) AS object_name,
           (SELECT COUNT(*)
            FROM dbo.customer AS c
            WHERE c.customer_id = 42
               OR c.full_name = N'Subject_0000042'
               OR c.email = N'subject42@example.invalid'
               OR c.phone = N'+1-555-0000042') AS rows_found
    UNION ALL
    SELECT CAST('reporting.customer_replica' AS nvarchar(256)),
           (SELECT COUNT(*)
            FROM reporting.customer_replica AS r
            WHERE r.customer_id = 42
               OR r.full_name = N'Subject_0000042'
               OR r.email = N'subject42@example.invalid'
               OR r.phone = N'+1-555-0000042')
) AS v
ORDER BY v.object_name;
