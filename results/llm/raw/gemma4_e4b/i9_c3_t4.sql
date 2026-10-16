WITH SearchResults AS (
    -- 1. Check the current active table (dbo.customer) - Should be zero after DELETE
    SELECT
        'dbo.customer' AS object_name,
        ISNULL(T1.Count, 0) AS rows_found
    FROM (
        SELECT COUNT(*) AS Count
        FROM dbo.customer c
        WHERE c.customer_id = 42
          AND c.full_name = 'Subject_0000042'
          AND c.email = 'subject42@example.invalid'
          AND c.phone LIKE '+1-555-0000042%' -- Using LIKE for phone robustness, though exact match is fine here
    ) AS T1

    UNION ALL

    -- 2. Check the temporal history table (dbo.customer_history) - Most likely location of remnant data
    SELECT
        'dbo.customer_history' AS object_name,
        ISNULL(T2.Count, 0) AS rows_found
    FROM (
        SELECT COUNT(*) AS Count
        FROM dbo.customer_history h
        WHERE h.customer_id = 42
          AND EXISTS (
              SELECT 1 FROM (VALUES ('Subject_0000042')) AS NameCheck(name) WHERE NameCheck.name = h.full_name
          )
          OR EXISTS (
              SELECT 1 FROM (VALUES ('subject42@example.invalid')) AS EmailCheck(email) WHERE EmailCheck.email = h.email
          )
          OR EXISTS (
              SELECT 1 FROM (VALUES ('+1-555-0000042')) AS PhoneCheck(phone) WHERE PhoneCheck.phone LIKE h.phone
          )
    ) AS T2

    -- Note: Since the schema implies only these two tables, we stop here.
    -- If other downstream copies (e.g., dbo.customer_archive or materialized views) existed, they would be added with UNION ALL.
)
SELECT object_name, rows_found FROM SearchResults;
