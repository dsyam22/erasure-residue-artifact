SET NOCOUNT ON;

-- Each checked object is returned, with the number of rows still holding the
-- subject's original name, email or phone. customer_id is not used as a match
-- key because it is not personal data on its own and could be reused.
SELECT N'dbo.customer' AS object_name,
       COUNT(*) AS rows_found
FROM dbo.customer
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042'
UNION ALL
SELECT N'dbo.customer_history' AS object_name,
       COUNT(*) AS rows_found
FROM dbo.customer_history
WHERE full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';
