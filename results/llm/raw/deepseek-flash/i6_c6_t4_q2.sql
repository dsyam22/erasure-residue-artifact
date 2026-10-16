-- QUERY
SELECT COUNT(*) AS phone_hits_in_customer
FROM dbo.customer
WHERE full_name LIKE N'%+1-555-0000042%'
   OR email LIKE N'%+1-555-0000042%';
