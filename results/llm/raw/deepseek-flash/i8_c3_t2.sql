/* Read-only verification: does any object in llm_i8 still hold Subject_0000042's original data? */

DECLARE @cid int = 42;
DECLARE @fn nvarchar(200) = N'Subject_0000042';
DECLARE @em nvarchar(320) = N'subject42@example.invalid';
DECLARE @ph nvarchar(50)  = N'+1-555-0000042';

CREATE TABLE #res (object_name sysname, rows_found bigint);

/* 1. Base table dbo.customer */
INSERT INTO #res
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @fn
   OR email = @em
   OR phone = @ph;

/* 2. CDC change tables, if CDC is enabled (cdc_enabled=0, so normally none) */
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'customer_CT' AND schema_id = SCHEMA_ID('cdc'))
BEGIN
    INSERT INTO #res
    SELECT N'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @cid
       OR full_name = @fn
       OR email = @em
       OR phone = @ph;
END
ELSE
    INSERT INTO #res VALUES (N'cdc.dbo_customer_CT', 0);

/* 3. Temporal history table, if dbo.customer were system-versioned */
IF EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.tables h ON h.object_id = t.history_table_id
    WHERE t.object_id = OBJECT_ID('dbo.customer')
)
BEGIN
    DECLARE @hist sysname =
        (SELECT QUOTENAME(SCHEMA_NAME(h.schema_id)) + '.' + QUOTENAME(h.name)
         FROM sys.tables t
         JOIN sys.tables h ON h.object_id = t.history_table_id
         WHERE t.object_id = OBJECT_ID('dbo.customer'));

    INSERT INTO #res
    EXEC (N'SELECT ' + QUOTENAME(@hist, '''') + N', COUNT(*) FROM ' + @hist +
          N' WHERE customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph');
END
ELSE
    INSERT INTO #res VALUES (N'dbo.customer_history (temporal)', 0);

/* 4. Change tracking side table, if change tracking were enabled */
IF EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID('dbo.customer'))
BEGIN
    INSERT INTO #res
    SELECT N'sys.dm_tran_commit_table (change tracking)', COUNT(*)
    FROM sys.dm_tran_commit_table ct
    WHERE EXISTS (
        SELECT 1
        FROM CHANGETABLE(CHANGES dbo.customer, 0) ch
        WHERE ch.customer_id = @cid
    );
END
ELSE
    INSERT INTO #res VALUES (N'sys.dm_tran_commit_table (change tracking)', 0);

SELECT object_name, rows_found FROM #res;

DROP TABLE #res;
