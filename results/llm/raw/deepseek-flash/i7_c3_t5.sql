DECLARE @cid int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found int);

/* dbo.customer */
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* reporting.customer_replica */
INSERT INTO #results (object_name, rows_found)
SELECT 'reporting.customer_replica', COUNT(*)
FROM reporting.customer_replica
WHERE customer_id = @cid
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* Any other user tables that carry a customer_id / name / email / phone column */
DECLARE @schema sysname, @table sysname, @sql nvarchar(max);
DECLARE @checked TABLE (schema_name sysname, table_name sysname);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name, t.name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND NOT (s.name = 'dbo' AND t.name = 'customer')
  AND NOT (s.name = 'reporting' AND t.name = 'customer_replica')
  AND NOT (s.name = 'cdc')
  AND NOT (t.name LIKE '%_history')
  AND NOT (t.name LIKE 'systranschemas%');

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table;
WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @has_cid bit = 0, @has_name bit = 0, @has_email bit = 0, @has_phone bit = 0;
    SELECT @has_cid = MAX(CASE WHEN c.name = 'customer_id' THEN 1 ELSE 0 END),
           @has_name = MAX(CASE WHEN c.name IN ('full_name','name','customer_name') THEN 1 ELSE 0 END),
           @has_email = MAX(CASE WHEN c.name IN ('email','email_address') THEN 1 ELSE 0 END),
           @has_phone = MAX(CASE WHEN c.name IN ('phone','phone_number') THEN 1 ELSE 0 END)
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + '.' + QUOTENAME(@table));

    IF (@has_cid = 1 OR @has_name = 1 OR @has_email = 1 OR @has_phone = 1)
    BEGIN
        DECLARE @pred nvarchar(max) = N'';
        IF @has_cid = 1 SET @pred = @pred + N'customer_id = @cid OR ';
        IF @has_name = 1 SET @pred = @pred + N'full_name = @full_name OR ';
        IF @has_email = 1 SET @pred = @pred + N'email = @email OR ';
        IF @has_phone = 1 SET @pred = @pred + N'phone = @phone OR ';
        SET @pred = LEFT(@pred, LEN(@pred) - 3);

        SET @sql = N'INSERT INTO #results (object_name, rows_found)
                     SELECT @obj, COUNT(*) FROM ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) +
                   N' WHERE ' + @pred;

        BEGIN TRY
            EXEC sp_executesql @sql,
                N'@obj sysname, @cid int, @full_name nvarchar(200), @email nvarchar(200), @phone nvarchar(200)',
                @obj = @schema + '.' + @table, @cid = @cid, @full_name = @full_name,
                @email = @email, @phone = @phone;
        END TRY
        BEGIN CATCH
            INSERT INTO #results (object_name, rows_found) VALUES (@schema + '.' + @table, 0);
        END CATCH;
    END

    FETCH NEXT FROM cur INTO @schema, @table;
END
CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found FROM #results ORDER BY object_name;

DROP TABLE #results;
