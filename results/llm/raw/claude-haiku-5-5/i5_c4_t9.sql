SET NOCOUNT ON;

-- Checks every object that holds customer rows (current table and its temporal history table).
-- A row counts as remaining personal data if it has the subject's customer_id, or any of the
-- subject's original full_name, email, or phone values.
SELECT
    N'dbo.customer' AS object_name,
    (SELECT COUNT(*)
     FROM dbo.customer AS c
     WHERE c.customer_id = 42
        OR c.full_name = N'Subject_0000042'
        OR c.email = N'subject42@example.invalid'
        OR c.phone = N'+1-555-0000042') AS rows_found
UNION ALL
SELECT
    N'dbo.customer_history',
    (SELECT COUNT(*)
     FROM dbo.customer_history AS h
     WHERE h.customer_id = 42
        OR h.full_name = N'Subject_0000042'
        OR h.email = N'subject42@example.invalid'
        OR h.phone = N'+1-555-0000042');
