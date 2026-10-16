-- SCRIPT
SET NOCOUNT ON;

SELECT 'dbo.customer' AS object_name,
       COUNT(*) AS rows_found
FROM dbo.customer AS t
WHERE t.full_name = N'Subject_0000042'
   OR t.email = N'subject42@example.invalid'
   OR t.phone = N'+1-555-0000042'

UNION ALL

SELECT 'dbo.customer_history' AS object_name,
       COUNT(*) AS rows_found
FROM dbo.customer_history AS h
WHERE h.full_name = N'Subject_0000042'
   OR h.email = N'subject42@example.invalid'
   OR h.phone = N'+1-555-0000042';
