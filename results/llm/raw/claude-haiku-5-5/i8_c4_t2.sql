SET NOCOUNT ON;

SELECT v.object_name,
       v.rows_found
FROM (
    SELECT N'dbo.customer' AS object_name,
           (SELECT COUNT(*)
            FROM dbo.customer c
            WHERE c.customer_id = 42
               OR c.full_name = N'Subject_0000042'
               OR c.email = N'subject42@example.invalid'
               OR c.phone = N'+1-555-0000042') AS rows_found
) AS v;
