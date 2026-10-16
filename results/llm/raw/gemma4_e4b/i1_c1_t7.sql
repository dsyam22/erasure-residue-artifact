WITH SearchResults AS (
    SELECT
        -- We explicitly name the object checked
        CAST('dbo.customer' AS NVARCHAR(128)) AS object_name,
        -- Count any rows that match the subject's data across any key field
        COUNT(c.customer_id) AS rows_found
    FROM dbo.customer c
    WHERE 
        c.customer_id = 42 
        OR c.full_name = 'Subject_0000042'
        OR c.email = 'subject42@example.invalid'
        OR c.phone = '+1-555-0000042'
)
SELECT object_name, rows_found 
FROM SearchResults;
