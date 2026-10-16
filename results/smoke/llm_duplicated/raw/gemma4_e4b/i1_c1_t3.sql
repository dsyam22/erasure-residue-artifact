SELECT
    'dbo.customer' AS object_name,
    (
        SELECT COUNT(*)
        FROM dbo.customer c
        WHERE 1 = 1 -- Placeholder condition for the join/scope
          AND (
              c.customer_id = 42 OR
              c.full_name = 'Subject_0000042' OR
              c.email = 'subject42@example.invalid' OR
              c.phone = '+1-555-0000042'
          )
    ) AS rows_found;
