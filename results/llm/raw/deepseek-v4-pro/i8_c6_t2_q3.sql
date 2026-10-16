-- QUERY
SELECT 
    'customer' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN customer_id = 42 THEN 1 ELSE 0 END) AS id_match,
    SUM(CASE WHEN full_name = N'Subject_0000042' THEN 1 ELSE 0 END) AS name_match,
    SUM(CASE WHEN email = N'subject42@example.invalid' THEN 1 ELSE 0 END) AS email_match,
    SUM(CASE WHEN phone = N'+1-555-0000042' THEN 1 ELSE 0 END) AS phone_match
FROM dbo.customer;
