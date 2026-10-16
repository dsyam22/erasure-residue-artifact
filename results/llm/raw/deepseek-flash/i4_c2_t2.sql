SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @member_id   int = 42;
DECLARE @full_name   nvarchar(4000) = N'Subject_0000042';
DECLARE @email       nvarchar(4000) = N'subject42@example.invalid';
DECLARE @phone       nvarchar(4000) = N'+1-555-0000042';

DECLARE @cdc_instance sysname = N'dbo_customer';

CREATE TABLE #results
(
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

/* dbo.customer */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @customer_id
  AND (
        full_name = @full_name
     OR email     = @email
     OR phone     = @phone
      );

/* dbo.member */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member', COUNT_BIG(*)
FROM dbo.member
WHERE member_id = @member_id
  AND (
        full_name = @full_name
     OR email     = @email
     OR phone     = @phone
      );

/* dbo.member_history */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member_history', COUNT_BIG(*)
FROM dbo.member_history
WHERE member_id = @member_id
  AND (
        full_name = @full_name
     OR email     = @email
     OR phone     = @phone
      );

/* CDC capture instance: cdc.dbo_customer_CT */
IF EXISTS (SELECT 1 FROM cdc.change_tables WHERE capture_instance = @cdc_instance)
BEGIN
    DECLARE @ct_name sysname = N'cdc.' + @cdc_instance + N'_CT';
    DECLARE @sql nvarchar(max) = N'
        INSERT INTO #results (object_name, rows_found)
        SELECT @obj, COUNT_BIG(*)
        FROM ' + QUOTENAME(OBJECT_SCHEMA_NAME(OBJECT_ID(@ct_name))) + N'.' + QUOTENAME(OBJECT_NAME(OBJECT_ID(@ct_name))) + N'
        WHERE customer_id = @cid
          AND (
                full_name = @fn
             OR email     = @em
             OR phone     = @ph
              );';

    EXEC sp_executesql
        @sql,
        N'@obj sysname, @cid int, @fn nvarchar(4000), @em nvarchar(4000), @ph nvarchar(4000)',
        @obj = @ct_name,
        @cid = @customer_id,
        @fn  = @full_name,
        @em  = @email,
        @ph  = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    VALUES (N'cdc.dbo_customer_CT', 0);
END

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;
