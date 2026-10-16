SELECT
    'dbo.customer' AS object_name,
    (
        SELECT COUNT(*)
        FROM dbo.customer c
        WHERE c.customer_id = 42
          AND c.full_name = N'Subject_0000042'
          AND c.email = N'subject42@example.invalid'
          AND c.phone = N'+1-555-0000042'
    ) AS rows_found

UNION ALL

SELECT
    'reporting.customer_replica' AS object_name,
    (
        SELECT COUNT(*)
        FROM reporting.customer_replica r
        WHERE r.customer_id = 42
          AND r.full_name = N'Subject_0000042'
          AND r.email = N'subject42@example.invalid'
          AND r.phone = N'+1-555-0000042'
    ) AS rows_found;
