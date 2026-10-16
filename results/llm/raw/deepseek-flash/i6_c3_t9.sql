/* Read-only verification: is Subject_0000042's phone '+1-555-0000042' still stored anywhere? */
SET NOCOUNT ON;

DECLARE @phone nvarchar(100) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

/* 1. Base table dbo.customer (phone column dropped) */
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE EXISTS (
    SELECT 1
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID('dbo.customer')
      AND c.name IN ('phone','phone_number','telephone','tel','mobile','phone_no')
      AND CHARINDEX(@phone, CONVERT(nvarchar(max), (SELECT NULL))) IS NOT NULL
);

/* Fallback for base table if any phone-like column exists */
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE CONVERT(nvarchar(max), customer_id) + '|' +
      ISNULL(full_name, N'') + '|' +
      ISNULL(email, N'') LIKE N'%' + @phone + N'%';

/* 2. CDC capture instance change table cdc.dbo_customer_CT (captured_columns include phone) */
INSERT INTO #results (object_name, rows_found)
SELECT 'cdc.dbo_customer_CT', COUNT(*)
FROM cdc.dbo_customer_CT
WHERE EXISTS (
    SELECT 1
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID('cdc.dbo_customer_CT')
      AND c.name = 'phone'
      AND CONVERT(nvarchar(max), phone) LIKE N'%' + @phone + N'%'
);

/* 3. Any other CDC change tables in the database that might hold the phone */
INSERT INTO #results (object_name, rows_found)
SELECT QUOTENAME(s.name) + '.' + QUOTENAME(t.name), COUNT(*)
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE s.name = 'cdc'
  AND t.name <> 'dbo_customer_CT'
  AND c.name IN ('phone','phone_number','telephone','tel','mobile','phone_no')
GROUP BY QUOTENAME(s.name) + '.' + QUOTENAME(t.name);

/* 4. Temporal history tables (none expected, but check) */
INSERT INTO #results (object_name, rows_found)
SELECT QUOTENAME(s.name) + '.' + QUOTENAME(t.name), 0
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.temporal_type = 1
  AND NOT EXISTS (
      SELECT 1
      FROM sys.columns c
      WHERE c.object_id = t.object_id
        AND c.name IN ('phone','phone_number','telephone','tel','mobile','phone_no')
  );

/* 5. Scan all user tables for any column containing the phone value */
INSERT INTO #results (object_name, rows_found)
SELECT QUOTENAME(s.name) + '.' + QUOTENAME(t.name), COUNT(*)
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE t.is_ms_shipped = 0
  AND s.name NOT IN ('sys')
  AND c.system_type_id IN (167, 231, 175, 239, 35, 99) /* varchar, nvarchar, char, nchar, text, ntext */
GROUP BY QUOTENAME(s.name) + '.' + QUOTENAME(t.name);

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
