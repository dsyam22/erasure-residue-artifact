-- QUERY
SELECT
  (SELECT COUNT(*) FROM dbo.customer
     WHERE customer_id = 42 OR full_name = N'Subject_0000042'
        OR email = N'subject42@example.invalid' OR phone = N'+1-555-0000042') AS dbo_customer_hits,
  (SELECT COUNT(*) FROM reporting.customer_replica
     WHERE customer_id = 42 OR full_name = N'Subject_0000042'
        OR email = N'subject42@example.invalid' OR phone = N'+1-555-0000042') AS replica_hits;
