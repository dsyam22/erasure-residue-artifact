/* Read-only verification of residual personal data for customer_id / member_id 42 */

DECLARE @cid int = 42,
        @name nvarchar(200) = N'Subject_0000042',
        @email nvarchar(200) = N'subject42@example.invalid',
        @phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

/* Live tables */
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member', COUNT_BIG(*)
FROM dbo.member
WHERE member_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

/* Temporal history table */
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member_history', COUNT_BIG(*)
FROM dbo.member_history
WHERE member_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

/* CDC change table (only if it exists) */
IF OBJECT_ID(N'cdc.dbo_customer_CT', N'U') IS NOT NULL
    INSERT INTO #results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', COUNT_BIG(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @cid
       OR full_name = @name
       OR email = @email
       OR phone = @phone;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
