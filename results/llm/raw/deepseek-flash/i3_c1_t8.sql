/* Read-only verification of erasure for the data subject.
   Checks dbo.customer and dbo.member for any rows still containing the
   subject's original personal data. Returns one result set:
   object_name | rows_found */

DECLARE @customer_id int = 42;
DECLARE @member_id   int = 42;
DECLARE @full_name   nvarchar(200) = N'Subject_0000042';
DECLARE @email       nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone       nvarchar(50)  = N'+1-555-0000042';

DECLARE @results TABLE (
    object_name sysname,
    rows_found  bigint
);

/* dbo.customer: match on the identifying key or any of the personal data fields */
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name   = @full_name
   OR email       = @email
   OR phone       = @phone;

/* dbo.member: match on the identifying key or any of the personal data fields */
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.member',
       COUNT(*)
FROM dbo.member
WHERE member_id = @member_id
   OR full_name = @full_name
   OR email     = @email
   OR phone     = @phone;

SELECT object_name, rows_found
FROM @results;
