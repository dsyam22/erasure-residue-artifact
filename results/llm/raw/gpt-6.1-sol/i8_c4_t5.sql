USE [llm_i8];

-- Checks all currently queryable rows and columns in the only table
-- identified by the catalog inspection. Any original identifier or
-- personal-data string counts as a match, including embedded strings.
-- A zero count does not establish physical erasure: deleted-page remnants
-- and transaction-log records are not checked by this logical-row query.
SELECT
    N'dbo.customer' AS object_name,
    COUNT_BIG(*) AS rows_found
FROM dbo.customer AS c
WHERE c.customer_id = 42
   OR EXISTS
   (
       SELECT 1
       FROM (VALUES (c.full_name), (c.email), (c.phone)) AS v(original_value)
       CROSS JOIN
       (
           VALUES
               (N'Subject_0000042'),
               (N'subject42@example.invalid'),
               (N'+1-555-0000042')
       ) AS p(search_value)
       WHERE CHARINDEX(
           p.search_value COLLATE Latin1_General_100_BIN2,
           v.original_value COLLATE Latin1_General_100_BIN2
       ) > 0
   );
