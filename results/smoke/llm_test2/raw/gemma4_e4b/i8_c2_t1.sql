SELECT
    CAST('dbo.customer' AS NVARCHAR(128)) AS object_name,
    ISNULL((
        SELECT COUNT(*)
        FROM dbo.customer c
        WHERE c.customer_id = 42
          AND c.full_name = 'Subject_0000042'
          AND c.email = 'subject42@example.invalid'
          AND c.phone = '+1-555-0000042'
    ), 0) AS rows_found;
