/*
  Scope: the user table and persisted metadata readable with the supplied
  permissions. A zero count does not prove physical erasure: DELETE can leave
  data in transaction logs, ghost records, unallocated pages, and row versions.
  Query Store and other protected internal storage cannot be verified with the
  reported permissions. Backups and external copies are outside this scope.

  customer_id = 42 is matched only in its identifier column; matching "42"
  indiscriminately in text would produce unrelated hits.
*/
SELECT
    N'dbo.customer' AS object_name,
    COUNT_BIG(*) AS rows_found
FROM dbo.customer
WHERE customer_id = 42
   OR CHARINDEX(
          N'Subject_0000042',
          full_name COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'subject42@example.invalid',
          full_name COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'+1-555-0000042',
          full_name COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'Subject_0000042',
          email COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'subject42@example.invalid',
          email COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'+1-555-0000042',
          email COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'Subject_0000042',
          phone COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'subject42@example.invalid',
          phone COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'+1-555-0000042',
          phone COLLATE Latin1_General_100_BIN2
      ) > 0

UNION ALL

SELECT
    N'sys.sql_modules',
    COUNT_BIG(*)
FROM sys.sql_modules AS m
WHERE CHARINDEX(N'Subject_0000042',
                m.definition COLLATE Latin1_General_100_BIN2) > 0
   OR CHARINDEX(N'subject42@example.invalid',
                m.definition COLLATE Latin1_General_100_BIN2) > 0
   OR CHARINDEX(N'+1-555-0000042',
                m.definition COLLATE Latin1_General_100_BIN2) > 0

UNION ALL

SELECT
    N'sys.extended_properties',
    COUNT_BIG(*)
FROM sys.extended_properties AS p
CROSS APPLY
(
    SELECT
        CONVERT(nvarchar(max), p.value)
            COLLATE Latin1_General_100_BIN2 AS property_value,
        p.name COLLATE Latin1_General_100_BIN2 AS property_name
) AS v
WHERE CHARINDEX(N'Subject_0000042', v.property_value) > 0
   OR CHARINDEX(N'subject42@example.invalid', v.property_value) > 0
   OR CHARINDEX(N'+1-555-0000042', v.property_value) > 0
   OR CHARINDEX(N'Subject_0000042', v.property_name) > 0
   OR CHARINDEX(N'subject42@example.invalid', v.property_name) > 0
   OR CHARINDEX(N'+1-555-0000042', v.property_name) > 0;
