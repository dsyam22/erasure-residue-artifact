/*
  This checks the supplied table, not every possible storage location.

  A DELETE does not guarantee physical erasure: original data can remain in
  deallocated pages, ghost records, transaction logs, or other database objects.
  An exhaustive, schema-independent search cannot be implemented using only
  SELECT statements against the supplied schema. A zero count below therefore
  does not certify database-wide erasure.

  Run with sufficient permissions to read every row; row-level security can
  otherwise hide matches.
*/
SELECT
    N'dbo.customer' AS object_name,
    COUNT_BIG(*) AS rows_found
FROM [llm_i1].[dbo].[customer] AS c
WHERE c.customer_id = 42
   OR EXISTS
   (
       SELECT 1
       FROM
       (
           VALUES
               (CONVERT(nvarchar(max), c.full_name)),
               (CONVERT(nvarchar(max), c.email)),
               (CONVERT(nvarchar(max), c.phone))
       ) AS v(original_value)
       WHERE CHARINDEX(
                 N'Subject_0000042',
                 v.original_value COLLATE Latin1_General_100_BIN2
             ) > 0
          OR CHARINDEX(
                 N'subject42@example.invalid',
                 v.original_value COLLATE Latin1_General_100_BIN2
             ) > 0
          OR CHARINDEX(
                 N'+1-555-0000042',
                 v.original_value COLLATE Latin1_General_100_BIN2
             ) > 0
   );
