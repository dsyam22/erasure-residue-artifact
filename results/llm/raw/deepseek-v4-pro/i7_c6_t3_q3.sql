-- QUERY
SELECT 'reporting.customer_replica' AS object_name, 
       customer_id, full_name, email, phone
FROM reporting.customer_replica
WHERE customer_id = 42
   OR full_name = 'Subject_0000042'
   OR email = 'subject42@example.invalid'
   OR phone = '+1-555-0000042';
