SELECT
    CAST('dbo.customer' AS NVARCHAR(256)) AS object_name,
    (
        SELECT 
            COUNT(*) 
        FROM 
            dbo.customer WITH (NOLOCK) 
        WHERE 
            customer_id = 42 
            AND full_name = 'Subject_0000042' 
            AND email = 'subject42@example.invalid' 
            AND phone = '+1-555-0000042'
    ) AS rows_found;
