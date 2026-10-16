/* Read-only residual PII scan for Subject_0000042 (customer_id 42) */
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @nm  nvarchar(4000) = N'Subject_0000042';
DECLARE @em  nvarchar(4000) = N'subject42@example.invalid';
DECLARE @ph  nvarchar(4000) = N'+1-555-0000042';

CREATE TABLE #r (object_name sysname, rows_found bigint);

/* dbo.customer */
INSERT INTO #r (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @nm
   OR email = @em
   OR phone = @ph;

/* CDC change table: cdc.dbo_customer_CT */
IF OBJECT_ID(N'cdc.dbo_customer_CT') IS NOT NULL
BEGIN
    INSERT INTO #r (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @cid
       OR full_name = @nm
       OR email = @em
       OR phone = @ph;
END
ELSE
BEGIN
    INSERT INTO #r (object_name, rows_found) VALUES (N'cdc.dbo_customer_CT', 0);
END

/* Temporal history table, if any */
IF OBJECT_ID(N'dbo.customer_history') IS NOT NULL
BEGIN
    INSERT INTO #r (object_name, rows_found)
    SELECT N'dbo.customer_history', COUNT(*)
    FROM dbo.customer_history
    WHERE customer_id = @cid
       OR full_name = @nm
       OR email = @em
       OR phone = @ph;
END
ELSE
BEGIN
    INSERT INTO #r (object_name, rows_found) VALUES (N'dbo.customer_history', 0);
END

SELECT object_name, rows_found
FROM #r
ORDER BY object_name;

DROP TABLE #r;
