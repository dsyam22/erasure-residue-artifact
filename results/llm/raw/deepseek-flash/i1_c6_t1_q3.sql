-- QUERY
SELECT
    (SELECT COUNT(*) FROM dbo.customer WHERE customer_id = 42) AS by_id,
    (SELECT COUNT(*) FROM dbo.customer WHERE full_name = N'Subject_0000042') AS by_name,
    (SELECT COUNT(*) FROM dbo.customer WHERE email = N'subject42@example.invalid') AS by_email,
    (SELECT COUNT(*) FROM dbo.customer WHERE phone = N'+1-555-0000042') AS by_phone;
