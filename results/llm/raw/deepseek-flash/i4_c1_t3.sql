/* Read-only verification of erasure for Subject_0000042 (customer_id/member_id 42).
   Returns exactly one result set: object_name, rows_found. */

DECLARE @cid int = 42;
DECLARE @name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname NOT NULL, rows_found int NOT NULL);

/* dbo.customer: match original identifiers by key, count residual PII in scope. */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
  AND (
        full_name = @name
     OR email     = @email
     OR phone     = @phone
      );

/* dbo.member: same check keyed on member_id. */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = @cid
  AND (
        full_name = @name
     OR email     = @email
     OR phone     = @phone
      );

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
