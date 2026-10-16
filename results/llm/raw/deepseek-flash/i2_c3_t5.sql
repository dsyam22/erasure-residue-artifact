/* Read-only verification: is Subject_0000042's personal data still anywhere? */
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @fullname nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

/* Only objects that exist in this database are checked. */
CREATE TABLE #results (object_name sysname, rows_found bigint);

/* dbo.customer - current table */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @fullname
   OR email = @email
   OR phone = @phone;

/* dbo.customer_history - temporal history table (INFINITE retention) */
IF OBJECT_ID(N'dbo.customer_history', N'U') IS NOT NULL
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer_history',
       COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @cid
   OR full_name = @fullname
   OR email = @email
   OR phone = @phone;

/* Scan every other user table in the database for any column
   that could still hold the subject's original values.
   This covers CDC change tables (cdc.*), downstream copies, etc. */
DECLARE @schema sysname, @table sysname, @sql nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name, t.name
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND NOT (s.name = N'dbo' AND t.name IN (N'customer', N'customer_history'));

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @pred nvarchar(max) = N'';

    SELECT @pred = @pred +
        CASE WHEN @pred = N'' THEN N'' ELSE N' OR ' END +
        N'CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) IN ('
        + N'N''' + REPLACE(@fullname, N'''', N'''''') + N''', '
        + N'N''' + REPLACE(@email,    N'''', N'''''') + N''', '
        + N'N''' + REPLACE(@phone,    N'''', N'''''') + N''')'
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND c.system_type_id IN (167,231,175,239,35,99)   /* varchar, nvarchar, char, nchar, text, ntext */
      AND c.is_computed = 0;

    IF @pred <> N''
    BEGIN
        SET @sql = N'INSERT INTO #results (object_name, rows_found) '
                 + N'SELECT N''' + REPLACE(@schema + N'.' + @table, N'''', N'''''') + N''', COUNT(*) '
                 + N'FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';
        EXEC sp_executesql @sql;
    END
    ELSE
    BEGIN
        /* Table has no string columns - still report it as checked. */
        INSERT INTO #results (object_name, rows_found)
        VALUES (@schema + N'.' + @table, 0);
    END

    FETCH NEXT FROM cur INTO @schema, @table;
END

CLOSE cur;
DEALLOCATE cur;

/* If CDC is enabled at the database level, its change tables live in cdc schema
   and were already covered by the scan above. Add explicit entries for any
   cdc tables that exist but were somehow not picked up. */
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'cdc')
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.' + t.name, 0
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE s.name = N'cdc'
      AND NOT EXISTS (SELECT 1 FROM #results r WHERE r.object_name = N'cdc.' + t.name);
END

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
