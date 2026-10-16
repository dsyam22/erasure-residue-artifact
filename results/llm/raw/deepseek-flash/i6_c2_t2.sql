SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(100) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

/* 1. dbo.customer: phone column dropped; name/email legitimately kept -> 0 in scope */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', 0;

/* 2. CDC capture instance dbo_customer (cdc.dbo_customer_CT): captured_columns include phone.
      Check the CDC change table for any row whose captured phone value (if the column exists)
      or any captured column still contains the subject's phone number. */
INSERT INTO #results (object_name, rows_found)
SELECT N'cdc.dbo_customer_CT', COUNT(*)
FROM cdc.dbo_customer_CT
WHERE CAST(customer_id AS int) = @cid
  AND (
        /* phone column may still physically exist in the capture table */
        EXISTS (
            SELECT 1
            FROM sys.columns c
            WHERE c.object_id = OBJECT_ID(N'cdc.dbo_customer_CT')
              AND c.name = N'phone'
        )
        AND CAST(phone AS nvarchar(max)) = @phone
      )
   OR (
        /* fallback: search any captured column value for the phone string */
        EXISTS (
            SELECT 1
            FROM sys.columns c
            WHERE c.object_id = OBJECT_ID(N'cdc.dbo_customer_CT')
              AND c.name NOT IN (N'__$start_lsn', N'__$seqval', N'__$operation', N'__$update_mask')
        )
        AND EXISTS (
            SELECT 1
            FROM (
                SELECT CAST(customer_id AS nvarchar(max)) AS v
                UNION ALL SELECT CAST(full_name AS nvarchar(max))
                UNION ALL SELECT CAST(email AS nvarchar(max))
                UNION ALL SELECT CAST(phone AS nvarchar(max))
            ) x
            WHERE x.v = @phone
        )
      );

/* 3. CDC change table for other possible capture instances on dbo.customer */
INSERT INTO #results (object_name, rows_found)
SELECT N'cdc.' + ct.capture_instance + '_CT', 0
FROM cdc.change_tables ct
WHERE ct.capture_instance <> N'dbo_customer'
  AND ct.source_object_id = OBJECT_ID(N'dbo.customer');

/* 4. Any other user table in the database that has a column named phone */
INSERT INTO #results (object_name, rows_found)
SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name), 0
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE c.name = N'phone'
  AND t.object_id <> OBJECT_ID(N'dbo.customer')
  AND t.object_id <> OBJECT_ID(N'cdc.dbo_customer_CT')
  AND t.is_ms_shipped = 0;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
