/* Read-only verification of residual personal data for subject 42 */
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @mid int = 42;
DECLARE @full_name nvarchar(4000) = N'Subject_0000042';
DECLARE @email nvarchar(4000) = N'subject42@example.invalid';
DECLARE @phone nvarchar(4000) = N'+1-555-0000042';

IF OBJECT_ID('tempdb..#results') IS NOT NULL DROP TABLE #results;
CREATE TABLE #results (object_name sysname NOT NULL, rows_found bigint NOT NULL);

/* dbo.customer */
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
  AND (
        full_name = @full_name
     OR email = @email
     OR phone = @phone
      );

/* dbo.member */
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member', COUNT_BIG(*)
FROM dbo.member
WHERE member_id = @mid
  AND (
        full_name = @full_name
     OR email = @email
     OR phone = @phone
      );

/* dbo.member_history (system-versioned temporal history) */
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member_history', COUNT_BIG(*)
FROM dbo.member_history
WHERE member_id = @mid
  AND (
        full_name = @full_name
     OR email = @email
     OR phone = @phone
      );

/* CDC capture table for dbo.customer, if present */
IF OBJECT_ID('cdc.dbo_customer_CT') IS NOT NULL
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', COUNT_BIG(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @cid
      AND (
            full_name = @full_name
         OR email = @email
         OR phone = @phone
          );
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    VALUES ('cdc.dbo_customer_CT', 0);
END;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
