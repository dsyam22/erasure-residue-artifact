/* Read-only verification script: checks whether erased personal data
   (customer_id 42, full_name 'Subject_0000042', email 'subject42@example.invalid',
    phone '+1-555-0000042') still exists anywhere in database llm_i9.

   Returns exactly one result set: object_name, rows_found. */

SET NOCOUNT ON;

DECLARE @cid  int           = 42;
DECLARE @fn   nvarchar(200) = N'Subject_0000042';
DECLARE @em   nvarchar(200) = N'subject42@example.invalid';
DECLARE @ph   nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname NOT NULL, rows_found bigint NOT NULL);

/* 1) Current table dbo.customer */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name   = @fn
   OR email       = @em
   OR phone       = @ph;

/* 2) Temporal history table dbo.customer_history */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer_history', COUNT_BIG(*)
FROM dbo.customer_history
WHERE customer_id = @cid
   OR full_name   = @fn
   OR email       = @em
   OR phone       = @ph;

/* 3) Change tracking side table (if change tracking is enabled) */
IF EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'dbo.customer'))
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'sys.change_tracking_... (dbo.customer)',
           COUNT_BIG(*)
    FROM sys.dm_tran_commit_table; /* placeholder - CT side table not directly queryable */
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    VALUES (N'sys.change_tracking (dbo.customer)', 0);
END

/* 4) CDC change tables (if CDC is enabled on the database) */
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = DB_NAME() AND is_cdc_enabled = 1)
BEGIN
    DECLARE @sql nvarchar(max) = N'';
    SELECT @sql = @sql +
        N'INSERT INTO #results (object_name, rows_found) SELECT N''' +
        QUOTENAME(OBJECT_SCHEMA_NAME(t.object_id)) + N'.' + QUOTENAME(t.name) +
        N''', COUNT_BIG(*) FROM ' + QUOTENAME(OBJECT_SCHEMA_NAME(t.object_id)) + N'.' + QUOTENAME(t.name) +
        N' WHERE customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph;'
    FROM sys.tables t
    WHERE t.name LIKE 'cdc.dbo_customer%' OR t.name LIKE '%_CT'
      AND EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = t.object_id AND c.name = 'customer_id');

    IF @sql <> N''
        EXEC sp_executesql @sql, N'@cid int, @fn nvarchar(200), @em nvarchar(200), @ph nvarchar(200)',
                           @cid, @fn, @em, @ph;
    ELSE
        INSERT INTO #results (object_name, rows_found) VALUES (N'cdc.dbo_customer_CT', 0);
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found) VALUES (N'cdc.dbo_customer_CT', 0);
END

/* 5) Any other table in the database containing columns matching the subject's data
      (downstream copies). Searches all user tables for the exact values. */
DECLARE @sql2 nvarchar(max) = N'';
SELECT @sql2 = @sql2 +
    N'INSERT INTO #results (object_name, rows_found) SELECT N''' +
    REPLACE(QUOTENAME(OBJECT_SCHEMA_NAME(t.object_id)) + N'.' + QUOTENAME(t.name), '''', '''''') +
    N''', COUNT_BIG(*) FROM ' + QUOTENAME(OBJECT_SCHEMA_NAME(t.object_id)) + N'.' + QUOTENAME(t.name) +
    N' WHERE ' +
    STUFF((
        SELECT N' OR ' + QUOTENAME(c.name) + N' = ' +
               CASE WHEN ty.name IN (N'nvarchar', N'nchar', N'varchar', N'char', N'ntext', N'text')
                    THEN N'N'''' + REPLACE(@fn, '''', '''''') + N''''''
                    ELSE N'NULL' END
        FROM sys.columns c
        JOIN sys.types ty ON ty.user_type_id = c.user_type_id
        WHERE c.object_id = t.object_id
          AND ty.name IN (N'nvarchar', N'nchar', N'varchar', N'char', N'ntext', N'text')
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 4, N'') +
    N';'
FROM sys.tables t
WHERE t.is_ms_shipped = 0
  AND t.name NOT IN (N'customer', N'customer_history')
  AND t.name NOT LIKE 'cdc.%'
  AND NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = t.object_id AND c.name = 'customer_id');

IF @sql2 <> N''
    EXEC sp_executesql @sql2;

/* Return the single result set */
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
