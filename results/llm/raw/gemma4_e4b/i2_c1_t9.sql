WITH SubjectCheck AS (
    SELECT 
        COUNT(*) AS RowCount
    FROM dbo.customer c
    WHERE 
        c.full_name = 'Subject_0000042' OR
        c.email = 'subject42@example.invalid' OR
        c.phone = '+1-555-0000042' OR
        CAST(c.customer_id AS nvarchar) = '42' -- Checking ID as string representation just in case of non-standard storage
)
SELECT 
    N'dbo.customer' AS object_name, 
    ISNULL(s.RowCount, 0) AS rows_found
FROM SubjectCheck s;
