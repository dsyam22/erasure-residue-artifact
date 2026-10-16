/* Read-only verification: search for the subject's original personal data
   across all relevant tables/columns in the database. */

DECLARE @cid   int           = 42;
DECLARE @name  nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

/* dbo.customer */
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name   = @name
   OR email       = @email
   OR phone       = @phone;

/* dbo.member */
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member',
       COUNT(*)
FROM dbo.member
WHERE member_id = @cid
   OR full_name = @name
   OR email     = @email
   OR phone     = @phone;

/* Any other base table in the database that has a column whose name suggests
   it may store personal data. Scans those columns for the subject's values. */
DECLARE @schema sysname, @table sysname, @col sysname;
DECLARE @sql nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, c.name
    FROM sys.columns c
    JOIN sys.tables  t ON t.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
      AND c.name IN ('customer_id','member_id','full_name','email','phone')
      AND NOT (s.name = 'dbo' AND t.name IN ('customer','member'))
    ORDER BY s.name, t.name, c.name;

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table, @col;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
        INSERT INTO #results (object_name, rows_found)
        SELECT @obj,
               COUNT(*)
        FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
        WHERE ' + QUOTENAME(@col) + N' = @val;';

    DECLARE @obj sysname = @schema + N'.' + @table;
    DECLARE @val nvarchar(200);

    IF @col IN ('customer_id','member_id')
        SET @val = CAST(@cid AS nvarchar(200));
    ELSE IF @col = 'full_name'
        SET @val = @name;
    ELSE IF @col = 'email'
        SET @val = @email;
    ELSE
        SET @val = @phone;

    EXEC sp_executesql @sql,
         N'@obj sysname, @val nvarchar(200)',
         @obj = @obj, @val = @val;

    FETCH NEXT FROM cur INTO @schema, @table, @col;
END

CLOSE cur;
DEALLOCATE cur;

/* Collapse any duplicate object rows (multiple matching columns in one table)
   and return exactly one result set. */
SELECT object_name, SUM(rows_found) AS rows_found
FROM #results
GROUP BY object_name
ORDER BY object_name;

DROP TABLE #results;
