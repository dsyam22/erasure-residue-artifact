SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @member_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

DECLARE @results TABLE (
    object_name sysname NOT NULL,
    rows_found bigint NOT NULL
);

/* dbo.customer */
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* dbo.member */
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.member', COUNT_BIG(*)
FROM dbo.member
WHERE member_id = @member_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* dbo.member_history */
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.member_history', COUNT_BIG(*)
FROM dbo.member_history
WHERE member_id = @member_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* cdc.dbo_customer_CT */
IF OBJECT_ID(N'cdc.dbo_customer_CT', N'U') IS NOT NULL
BEGIN
    INSERT INTO @results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', COUNT_BIG(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END
ELSE
BEGIN
    INSERT INTO @results (object_name, rows_found)
    VALUES (N'cdc.dbo_customer_CT', 0);
END;

/* cdc change table for member, if present */
IF OBJECT_ID(N'cdc.dbo_member_CT', N'U') IS NOT NULL
BEGIN
    INSERT INTO @results (object_name, rows_found)
    SELECT N'cdc.dbo_member_CT', COUNT_BIG(*)
    FROM cdc.dbo_member_CT
    WHERE member_id = @member_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END
ELSE
BEGIN
    INSERT INTO @results (object_name, rows_found)
    VALUES (N'cdc.dbo_member_CT', 0);
END;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
