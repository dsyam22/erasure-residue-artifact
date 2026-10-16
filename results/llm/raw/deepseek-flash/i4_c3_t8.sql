/* Read-only verification: does the subject's original personal data still exist anywhere? */
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @mid int = 42;
DECLARE @name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50)  = N'+1-555-0000042';

/* Normalized search values */
DECLARE @nameNorm  nvarchar(200) = N'Subject_0000042';
DECLARE @emailNorm nvarchar(320) = N'subject42@example.invalid';
DECLARE @phoneNorm nvarchar(50)  = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname NOT NULL, rows_found bigint NOT NULL);

/* 1. dbo.customer (current rows) */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE (customer_id = @cid)
   OR (full_name = @name)
   OR (email = @email)
   OR (phone = @phone);

/* 2. dbo.member (current rows) */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member', COUNT(*)
FROM dbo.member
WHERE (member_id = @mid)
   OR (full_name = @name)
   OR (email = @email)
   OR (phone = @phone);

/* 3. dbo.member_history (temporal history) */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member_history', COUNT(*)
FROM dbo.member_history
WHERE (member_id = @mid)
   OR (full_name = @name)
   OR (email = @email)
   OR (phone = @phone);

/* 4. CDC change table for dbo.customer (if it exists) */
IF OBJECT_ID(N'cdc.dbo_customer_CT', N'U') IS NOT NULL
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE (customer_id = @cid)
       OR (full_name = @name)
       OR (email = @email)
       OR (phone = @phone);
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found) VALUES (N'cdc.dbo_customer_CT', 0);
END

SELECT object_name, rows_found FROM #results;

DROP TABLE #results;
