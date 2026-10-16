-- QUERY
SELECT r.customer_id, r.full_name, r.email, r.phone
FROM reporting.customer_replica AS r
WHERE r.customer_id = 42
   OR r.full_name = N'Subject_0000042'
   OR r.email = N'subject42@example.invalid'
   OR r.phone = N'+1-555-0000042';
