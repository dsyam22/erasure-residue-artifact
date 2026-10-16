/* Read-only verification: does the erased subject's original personal data
   still exist anywhere in this database?
   Returns exactly one result set: object_name, rows_found
   Note: CDC is disabled at database level and dbo.customer is NON_TEMPORAL,
   so no CDC change tables / temporal history tables exist for it. We still
   probe for them defensively and check downstream copies. */

SET NOCOUNT ON;

DECLARE @cid   int           = 42;
DECLARE @name  nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #res (object_name sysname, rows_found bigint);

/* ---------- 1. The base table itself ---------- */
IF OBJECT_ID(N'dbo.customer', N'U') IS NOT NULL
BEGIN
    INSERT INTO #res
    SELECT N'dbo.customer',
           COUNT(*)
    FROM dbo.customer
    WHERE customer_id = @cid
       OR full_name = @name
       OR email     = @email
       OR phone     = @phone;
END
ELSE
    INSERT INTO #res VALUES (N'dbo.customer', 0);

/* ---------- 2. Temporal history table (if customer were system-versioned) ---------- */
IF EXISTS (SELECT 1
           FROM sys.tables
           WHERE object_id = OBJECT_ID(N'dbo.customer')
             AND temporal_type IN (2, 4))          -- SYSTEM_VERSIONED
BEGIN
    DECLARE @hist sysname, @hsql nvarchar(max);

    SELECT @hist = QUOTENAME(OBJECT_SCHEMA_NAME(history_table_id))
                 + N'.' + QUOTENAME(OBJECT_NAME(history_table_id))
    FROM sys.tables
    WHERE object_id = OBJECT_ID(N'dbo.customer');

    SET @hsql = N'INSERT INTO #res SELECT @o, COUNT(*) FROM ' + @hist
              + N' WHERE customer_id = @c OR full_name = @n OR email = @e OR phone = @p;';

    EXEC sp_executesql @hsql,
         N'@o sysname, @c int, @n nvarchar(200), @e nvarchar(200), @p nvarchar(200)',
         @o = @hist, @c = @cid, @n = @name, @e = @email, @p = @phone;
END
ELSE
    INSERT INTO #res VALUES (N'dbo.customer (temporal history)', 0);

/* ---------- 3. CDC change tables (if any existed for the database/table) ---------- */
IF EXISTS (SELECT 1 FROM sys.tables WHERE is_ms_shipped = 1 AND name LIKE N'cdc.dbo_customer%')
   OR EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'cdc')
BEGIN
    DECLARE @ct sysname, @csql nvarchar(max);

    DECLARE cdc_cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT QUOTENAME(OBJECT_SCHEMA_NAME(object_id)) + N'.' + QUOTENAME(name)
        FROM sys.tables
        WHERE name LIKE N'dbo_customer%'
          AND OBJECT_SCHEMA_NAME(object_id) = N'cdc';

    OPEN cdc_cur;
    FETCH NEXT FROM cdc_cur INTO @ct;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @csql = N'INSERT INTO #res SELECT @o, COUNT(*) FROM ' + @ct
                  + N' WHERE customer_id = @c OR full_name = @n OR email = @e OR phone = @p;';

        EXEC sp_executesql @csql,
             N'@o sysname, @c int, @n nvarchar(200), @e nvarchar(200), @p nvarchar(200)',
             @o = @ct, @c = @cid, @n = @name, @e = @email, @p = @phone;

        FETCH NEXT FROM cdc_cur INTO @ct;
    END

    CLOSE cdc_cur;
    DEALLOCATE cdc_cur;
END
ELSE
    INSERT INTO #res VALUES (N'cdc change tables (dbo_customer)', 0);

/* ---------- 4. Change tracking side table (if enabled) ---------- */
IF EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'dbo.customer'))
BEGIN
    INSERT INTO #res
    SELECT N'sys.dm_tran_commit_table (change tracking)',
           COUNT(*)
    FROM sys.dm_tran_commit_table;
END
ELSE
    INSERT INTO #res VALUES (N'sys.dm_tran_commit_table (change tracking)', 0);

/* ---------- 5. Downstream copies / other tables containing the PII ---------- */
DECLARE @tbl sysname, @sch sysname, @col sysname, @sql nvarchar(max);
DECLARE @found bit;

DECLARE copy_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, c.name
    FROM sys.columns c
    JOIN sys.tables  t ON t.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE c.name IN (N'customer_id', N'full_name', N'email', N'phone')
      AND t.object_id <> OBJECT_ID(N'dbo.customer')
      AND t.is_ms_shipped = 0
      AND s.name <> N'cdc';

OPEN copy_cur;
FETCH NEXT FROM copy_cur INTO @sch, @tbl, @col;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@sch) + N'.' + QUOTENAME(@tbl)
             + N' WHERE ' + QUOTENAME(@col) + N' IN (@c, @n, @e, @p))'
             + N' INSERT INTO #res SELECT @o, COUNT(*) FROM ' + QUOTENAME(@sch) + N'.' + QUOTENAME(@tbl)
             + N' WHERE ' + QUOTENAME(@col) + N' IN (@c, @n, @e, @p);';

    EXEC sp_executesql @sql,
         N'@o sysname, @c int, @n nvarchar(200), @e nvarchar(200), @p nvarchar(200)',
         @o = @sch + N'.' + @tbl, @c = @cid, @n = @name, @e = @email, @p = @phone;

    FETCH NEXT FROM copy_cur INTO @sch, @tbl, @col;
END

CLOSE copy_cur;
DEALLOCATE copy_cur;

/* ---------- Result ---------- */
SELECT object_name,
       SUM(rows_found) AS rows_found
FROM #res
GROUP BY object_name
ORDER BY object_name;

DROP TABLE #res;
