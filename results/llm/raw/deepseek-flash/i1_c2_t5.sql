SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @fn nvarchar(200) = N'Subject_0000042';
DECLARE @em nvarchar(320) = N'subject42@example.invalid';
DECLARE @ph nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #res (object_name sysname, rows_found bigint);

/* dbo.customer */
INSERT INTO #res (object_name, rows_found)
SELECT N'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @fn
   OR email = @em
   OR phone = @ph;

/* CDC capture table cdc.dbo_customer_CT */
IF OBJECT_ID(N'cdc.dbo_customer_CT') IS NOT NULL
BEGIN
    INSERT INTO #res (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', COUNT_BIG(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @cid
       OR full_name = @fn
       OR email = @em
       OR phone = @ph;
END
ELSE
BEGIN
    INSERT INTO #res (object_name, rows_found) VALUES (N'cdc.dbo_customer_CT', 0);
END

/* CDC change table function (if capture instance exists) */
IF EXISTS (SELECT 1 FROM cdc.change_tables WHERE capture_instance = N'dbo_customer')
BEGIN
    INSERT INTO #res (object_name, rows_found)
    SELECT N'cdc.fn_cdc_get_all_changes_dbo_customer', COUNT_BIG(*)
    FROM cdc.fn_cdc_get_all_changes_dbo_customer(
             sys.fn_cdc_get_min_lsn(N'dbo_customer'),
             sys.fn_cdc_get_max_lsn(),
             N'all')
    WHERE customer_id = @cid
       OR full_name = @fn
       OR email = @em
       OR phone = @ph;
END
ELSE
BEGIN
    INSERT INTO #res (object_name, rows_found) VALUES (N'cdc.fn_cdc_get_all_changes_dbo_customer', 0);
END

SELECT object_name, rows_found FROM #res;

DROP TABLE #res;
