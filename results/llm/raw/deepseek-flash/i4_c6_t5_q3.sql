-- QUERY
SELECT
    (SELECT COUNT(*) FROM dbo.customer WHERE customer_id = 42
        AND (full_name = N'Subject_0000042' OR email = N'subject42@example.invalid' OR phone = N'+1-555-0000042')) AS customer_hits,
    (SELECT COUNT(*) FROM dbo.member WHERE member_id = 42
        AND (full_name = N'Subject_0000042' OR email = N'subject42@example.invalid' OR phone = N'+1-555-0000042')) AS member_hits;
