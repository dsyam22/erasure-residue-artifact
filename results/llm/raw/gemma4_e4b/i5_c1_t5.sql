SELECT
    'dbo.customer' AS object_name,
    (
        SELECT COUNT(1)
        FROM dbo.customer
        WHERE full_name = 'Subject_0000042'
          AND email = 'subject42@example.invalid'
          AND phone = '+1-555-0000042'
    ) AS rows_found;
