SELECT
    N'dbo.customer' AS object_name,
    COUNT_BIG(*) AS rows_found
FROM llm_i8.dbo.customer
WHERE customer_id = 42
   OR CHARINDEX(
          N'Subject_0000042',
          full_name COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'subject42@example.invalid',
          email COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'+1-555-0000042',
          phone COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'Subject_0000042',
          email COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'Subject_0000042',
          phone COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'subject42@example.invalid',
          full_name COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'subject42@example.invalid',
          phone COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'+1-555-0000042',
          full_name COLLATE Latin1_General_100_BIN2
      ) > 0
   OR CHARINDEX(
          N'+1-555-0000042',
          email COLLATE Latin1_General_100_BIN2
      ) > 0;
