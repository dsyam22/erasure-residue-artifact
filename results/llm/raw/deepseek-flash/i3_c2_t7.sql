/* ============================================================================
   Read-only erasure verification for subject customer_id = 42
   Returns exactly one result set: object_name | rows_found
   ============================================================================ */

SET NOCOUNT ON;

DECLARE @cid    int           = 42;
DECLARE @name   nvarchar(200) = N'Subject_0000042';
DECLARE @email  nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone  nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

/* --- 1. dbo.customer ---------------------------------------------------- */
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @name
   OR email     = @email
   OR phone     = @phone;

/* --- 2. dbo.member ------------------------------------------------------ */
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member', COUNT_BIG(*)
FROM dbo.member
WHERE member_id = @cid
   OR full_name = @name
   OR email     = @email
   OR phone     = @phone;

/* --- 3. dbo.member_history (system-versioned temporal history) ---------- */
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member_history', COUNT_BIG(*)
FROM dbo.member_history
WHERE member_id = @cid
   OR full_name = @name
   OR email     = @email
   OR phone     = @phone;

/* --- 4. cdc.dbo_customer_CT (CDC change table) -------------------------- */
/* CDC change table is only guaranteed to be queryable via the CDC functions;
   however a direct SELECT is permitted and read-only. Columns captured:
   customer_id, full_name, email, phone. */
INSERT INTO #results (object_name, rows_found)
SELECT 'cdc.dbo_customer_CT', COUNT_BIG(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @cid
   OR full_name = @name
   OR email     = @email
   OR phone     = @phone;

/* --- 5. dbo.customer via CDC captured LSN window (cdc.fn_cdc_get_all_changes) ---
   Optional deeper check: CDC retains changes even after the source row is
   deleted; the change table above already covers retained rows. This block
   verifies the same data through the CDC API for completeness. */
DECLARE @from_lsn binary(10) = sys.fn_cdc_get_min_lsn('dbo_customer');
DECLARE @to_lsn   binary(10) = sys.fn_cdc_get_max_lsn();

IF @from_lsn IS NOT NULL AND @to_lsn IS NOT NULL
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'cdc.fn_cdc_get_all_changes_dbo_customer', COUNT_BIG(*)
    FROM cdc.fn_cdc_get_all_changes_dbo_customer(@from_lsn, @to_lsn, 'ALL')
    WHERE customer_id = @cid
       OR full_name = @name
       OR email     = @email
       OR phone     = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    VALUES ('cdc.fn_cdc_get_all_changes_dbo_customer', 0);
END

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
