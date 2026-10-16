-- QUERY
SELECT __$operation, customer_id, full_name, email, phone
FROM cdc.dbo_customer_CT
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';
