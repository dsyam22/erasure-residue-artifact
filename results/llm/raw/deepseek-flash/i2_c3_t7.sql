DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found bigint);

DECLARE @sql nvarchar(max);

-- dbo.customer
SET @sql = N'
INSERT INTO @r (object_name, rows_found)
SELECT N''dbo.customer'', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @fn
   OR email = @em
   OR phone = @ph;';
EXEC sp_executesql @sql,
    N'@cid int, @fn nvarchar(200), @em nvarchar(200), @ph nvarchar(200), @r nvarchar(200) OUTPUT',
    @cid = @customer_id, @fn = @full_name, @em = @email, @ph = @phone, @r = N'@results';

-- dbo.customer_history
SET @sql = N'
INSERT INTO @r (object_name, rows_found)
SELECT N''dbo.customer_history'', COUNT_BIG(*)
FROM dbo.customer_history
WHERE customer_id = @cid
   OR full_name = @fn
   OR email = @em
   OR phone = @ph;';
EXEC sp_executesql @sql,
    N'@cid int, @fn nvarchar(200), @em nvarchar(200), @ph nvarchar(200), @r nvarchar(200) OUTPUT',
    @cid = @customer_id, @fn = @full_name, @em = @email, @ph = @phone, @r = N'@results';

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
