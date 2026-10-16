SELECT
    'dbo.customer' AS object_name,
    (
        SELECT
            COUNT(*)
        FROM
            dbo.customer c
        WHERE
            c.customer_id = 42
            AND c.full_name = N'Subject_0000042'
            AND c.email = N'subject42@example.invalid'
            AND c.phone = N'+1-555-0000042'
    ) AS rows_found;
