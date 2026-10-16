/* Read-only verification: is Subject_0000042's original personal data still present? */

DECLARE @cid int = 42;
DECLARE @member_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

/* CDC capture instance for dbo.customer */
DECLARE @cdc_capture sysname = N'dbo_customer';

/* Build list of relevant CDC change tables (capture instance + any associated _CT) */
IF OBJECT_ID('tempdb..#results') IS NOT NULL DROP TABLE #results;
CREATE TABLE #results (object_name sysname NOT NULL, rows_found bigint NOT NULL);

/* 1. dbo.customer */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
  AND (
        full_name = @full_name
     OR email = @email
     OR phone = @phone
      );

/* 2. dbo.member (current row) */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member',
       COUNT_BIG(*)
FROM dbo.member
WHERE member_id = @member_id
  AND (
        full_name = @full_name
     OR email = @email
     OR phone = @phone
      );

/* 3. dbo.member_history (temporal history) */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member_history',
       COUNT_BIG(*)
FROM dbo.member_history
WHERE member_id = @member_id
  AND (
        full_name = @full_name
     OR email = @email
     OR phone = @phone
      );

/* 4. CDC change table for dbo.customer, if it exists */
IF OBJECT_ID(N'cdc.' + @cdc_capture + N'_CT') IS NOT NULL
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.' + @cdc_capture + N'_CT',
           COUNT_BIG(*)
    FROM cdc.[dbo_customer_CT]
    WHERE (
            full_name = @full_name
         OR email = @email
         OR phone = @phone
          );
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    VALUES (N'cdc.' + @cdc_capture + N'_CT', 0);
END

/* Return exactly one result set */
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
