/* ============================================================
   Read-only verification: is the erased personal data still
   present anywhere in the database?
   Returns exactly one result set: object_name, rows_found
   ============================================================ */

SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @member_id   int = 42;
DECLARE @full_name   nvarchar(200) = N'Subject_0000042';
DECLARE @email       nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone       nvarchar(50)  = N'+1-555-0000042';

CREATE TABLE #results
(
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

/* ---------- dbo.customer ---------- */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* ---------- dbo.member ---------- */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member',
       COUNT_BIG(*)
FROM dbo.member
WHERE member_id = @member_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* ---------- dbo.member_history (temporal history) ---------- */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member_history',
       COUNT_BIG(*)
FROM dbo.member_history
WHERE member_id = @member_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* ---------- cdc.dbo_customer_CT (CDC change table) ---------- */
INSERT INTO #results (object_name, rows_found)
SELECT N'cdc.dbo_customer_CT',
       COUNT_BIG(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* ---------- Output (single result set) ---------- */
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
