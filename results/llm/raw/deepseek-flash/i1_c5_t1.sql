-- SCRIPT
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @fn nvarchar(200) = N'Subject_0000042';
DECLARE @em nvarchar(200) = N'subject42@example.invalid';
DECLARE @ph nvarchar(200) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found bigint);

-- dbo.customer
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph;

-- cdc change table dbo_customer_CT
IF OBJECT_ID(N'dbo.dbo_customer_CT', N'U') IS NOT NULL
BEGIN
    INSERT INTO @results (object_name, rows_found)
    SELECT 'dbo.dbo_customer_CT', COUNT(*)
    FROM dbo.dbo_customer_CT
    WHERE customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph;
END
ELSE
BEGIN
    INSERT INTO @results (object_name, rows_found)
    SELECT 'dbo.dbo_customer_CT', CAST(0 AS bigint)
    WHERE 1 = 0;
    INSERT INTO @results (object_name, rows_found) VALUES ('dbo.dbo_customer_CT', 0);
END

SELECT object_name, rows_found FROM @results;
