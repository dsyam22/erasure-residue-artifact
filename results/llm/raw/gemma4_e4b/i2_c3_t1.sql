SELECT 'dbo.customer' AS object_name, COUNT(CASE WHEN customer_id = 42 AND full_name = 'Subject_0000042' THEN 1 END) AS rows_found
UNION ALL
SELECT 'dbo.customer_history', COUNT(CASE WHEN customer_id = 42 AND full_name = 'Subject_0000042' THEN 1 END)
