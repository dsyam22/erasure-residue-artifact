-- QUERY
SELECT 
    (SELECT COUNT(*) FROM dbo.customer WHERE customer_id = 42 OR full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042') AS customer_rows,
    (SELECT COUNT(*) FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo') AS dbo_table_count;
