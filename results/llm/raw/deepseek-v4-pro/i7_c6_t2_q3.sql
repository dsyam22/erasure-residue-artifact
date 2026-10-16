-- QUERY
SELECT COUNT(*) AS row_count
FROM reporting.customer_replica
WHERE customer_id = 42;

SELECT COUNT(*) AS row_count
FROM reporting.customer_replica
WHERE full_name = 'Subject_0000042';

SELECT COUNT(*) AS row_count
FROM reporting.customer_replica
WHERE email = 'subject42@example.invalid';

SELECT COUNT(*) AS row_count
FROM reporting.customer_replica
WHERE phone = '+1-555-0000042';
