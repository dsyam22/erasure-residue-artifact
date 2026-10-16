/* Read-only residual personal data check for subject customer_id/member_id 42.
   Returns exactly one result set: object_name, rows_found. */

DECLARE @cid int = 42;
DECLARE @mid int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found bigint);

/* dbo.customer */
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* dbo.member */
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.member', COUNT_BIG(*)
FROM dbo.member
WHERE member_id = @mid
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* dbo.member_history (temporal history) */
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.member_history', COUNT_BIG(*)
FROM dbo.member_history
WHERE member_id = @mid
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* CDC capture table for dbo.customer */
INSERT INTO @results (object_name, rows_found)
SELECT N'cdc.dbo_customer_CT', COUNT_BIG(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @cid
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

SELECT object_name, rows_found
FROM @results;
