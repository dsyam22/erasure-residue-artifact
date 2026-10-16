/* Read-only verification: does the erased subject's personal data still exist anywhere? */

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

/* 1. Primary table: dbo.customer */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* 2. Downstream replica: reporting.customer_replica */
INSERT INTO #results (object_name, rows_found)
SELECT N'reporting.customer_replica', COUNT_BIG(*)
FROM reporting.customer_replica
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* 3. CDC change tables (if CDC is/was enabled).
      CDC capture instances live in schema cdc with tables named <schema>_<table>_CT.
      We detect them dynamically and count matching rows. */
DECLARE @sql nvarchar(max) = N'';

SELECT @sql = @sql + N'
INSERT INTO #results (object_name, rows_found)
SELECT N''cdc.'' + QUOTENAME(ct.name), COUNT_BIG(*)
FROM cdc.' + QUOTENAME(ct.name) + N' AS t
WHERE 1 = 0'
FROM sys.tables AS ct
WHERE ct.schema_id = SCHEMA_ID(N'cdc')
  AND ct.name LIKE N'%[_]CT';

/* Build a proper dynamic scan for each CDC change table, checking all nvarchar
   columns for the subject's values (CDC tables have no fixed column layout). */
SET @sql = N'';

SELECT @sql = @sql + N'
INSERT INTO #results (object_name, rows_found)
SELECT N''cdc.' + REPLACE(ct.name, N'''', N'''''') + N''', COUNT_BIG(*)
FROM cdc.' + QUOTENAME(ct.name) + N' AS t
WHERE EXISTS (
    SELECT 1
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(N''cdc.' + REPLACE(ct.name, N'''', N'''''') + N''')
      AND c.system_type_id IN (167, 231, 175, 239)  /* varchar, nvarchar, char, nchar */
      AND (
            (c.name IN (N''full_name'', N''email'', N''phone'')
             AND EXISTS (
                 SELECT 1 FROM cdc.' + QUOTENAME(ct.name) + N' AS x
                 WHERE x.[' + REPLACE(c.name, N']', N']]') + N'] IN (@full_name, @email, @phone)
             ))
         OR (c.name = N''customer_id''
             AND EXISTS (
                 SELECT 1 FROM cdc.' + QUOTENAME(ct.name) + N' AS y
                 WHERE TRY_CONVERT(int, y.[customer_id]) = @customer_id
             ))
         )
);'
FROM sys.tables AS ct
WHERE ct.schema_id = SCHEMA_ID(N'cdc')
  AND ct.name LIKE N'%[_]CT';

IF @sql <> N''
BEGIN
    EXEC sp_executesql @sql,
        N'@customer_id int, @full_name nvarchar(200), @email nvarchar(320), @phone nvarchar(50)',
        @customer_id, @full_name, @email, @phone;
END

/* 4. Temporal history tables (if any table is/was system-versioned).
      Detect history tables dynamically. */
SET @sql = N'';

SELECT @sql = @sql + N'
INSERT INTO #results (object_name, rows_found)
SELECT N''' + REPLACE(SCHEMA_NAME(t.schema_id) + N'.' + t.name, N'''', N'''''') + N''', COUNT_BIG(*)
FROM ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name) + N' AS h
WHERE EXISTS (
    SELECT 1
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
      AND c.system_type_id IN (167, 231, 175, 239)
      AND (
            (c.name IN (N''full_name'', N''email'', N''phone'')
             AND EXISTS (
                 SELECT 1 FROM ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name) + N' AS x
                 WHERE x.[' + REPLACE(c.name, N']', N']]') + N'] IN (@full_name, @email, @phone)
             ))
         OR (c.name = N''customer_id''
             AND EXISTS (
                 SELECT 1 FROM ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name) + N' AS y
                 WHERE TRY_CONVERT(int, y.[customer_id]) = @customer_id
             ))
         )
);'
FROM sys.tables AS t
WHERE t.temporal_type = 1  /* HISTORY_TABLE */
  AND t.schema_id <> SCHEMA_ID(N'cdc');

IF @sql <> N''
BEGIN
    EXEC sp_executesql @sql,
        N'@customer_id int, @full_name nvarchar(200), @email nvarchar(320), @phone nvarchar(50)',
        @customer_id, @full_name, @email, @phone;
END

/* 5. Any other user table in the database that could hold a copy of the data.
      Scan all base user tables (excluding cdc schema and history tables already handled)
      for the subject's identifiers. */
SET @sql = N'';

SELECT @sql = @sql + N'
INSERT INTO #results (object_name, rows_found)
SELECT N''' + REPLACE(SCHEMA_NAME(t.schema_id) + N'.' + t.name, N'''', N'''''') + N''', COUNT_BIG(*)
FROM ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name) + N' AS s
WHERE EXISTS (
    SELECT 1
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
      AND c.system_type_id IN (167, 231, 175, 239)
      AND (
            (c.name IN (N''full_name'', N''email'', N''phone'')
             AND EXISTS (
                 SELECT 1 FROM ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name) + N' AS x
                 WHERE x.[' + REPLACE(c.name, N']', N']]') + N'] IN (@full_name, @email, @phone)
             ))
         OR (c.name = N''customer_id''
             AND EXISTS (
                 SELECT 1 FROM ' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name) + N' AS y
                 WHERE TRY_CONVERT(int, y.[customer_id]) = @customer_id
             ))
         )
);'
FROM sys.tables AS t
WHERE t.is_ms_shipped = 0
  AND t.schema_id <> SCHEMA_ID(N'cdc')
  AND t.temporal_type <> 1
  AND NOT (SCHEMA_NAME(t.schema_id) = N'dbo' AND t.name = N'customer')
  AND NOT (SCHEMA_NAME(t.schema_id) = N'reporting' AND t.name = N'customer_replica');

IF @sql <> N''
BEGIN
    EXEC sp_executesql @sql,
        N'@customer_id int, @full_name nvarchar(200), @email nvarchar(320), @phone nvarchar(50)',
        @customer_id, @full_name, @email, @phone;
END

/* Final single result set: one row per object checked, 0 where nothing found. */
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
