-- SCRIPT
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found bigint);

-- dbo.customer
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Search all other user tables in the database for any of the subject's values
DECLARE @schema sysname, @table sysname, @col sysname, @sql nvarchar(max);

DECLARE col_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name, t.name, c.name
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND c.system_type_id IN (167, 231, 175, 239, 231) -- varchar, nvarchar, char, nchar
  AND NOT (s.name = 'dbo' AND t.name = 'customer')
ORDER BY s.name, t.name, c.name;

OPEN col_cursor;
FETCH NEXT FROM col_cursor INTO @schema, @table, @col;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
    INSERT INTO @results (object_name, rows_found)
    SELECT @obj, COUNT(*)
    FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
    WHERE ' + QUOTENAME(@col) + N' IN (@v1, @v2, @v3);';

    -- Only count each table once; accumulate matches across columns
    -- Use a temp holder per table+column then merge
    DECLARE @obj sysname = @schema + N'.' + @table;

    BEGIN TRY
        EXEC sp_executesql @sql,
            N'@obj sysname, @v1 nvarchar(200), @v2 nvarchar(200), @v3 nvarchar(50)',
            @obj = @obj, @v1 = @full_name, @v2 = @email, @v3 = @phone;
    END TRY
    BEGIN CATCH
        -- ignore conversion/comparison errors on non-text columns
    END CATCH

    FETCH NEXT FROM col_cursor INTO @schema, @table, @col;
END

CLOSE col_cursor;
DEALLOCATE col_cursor;

-- Aggregate: one row per object, summing matches; ensure every checked table appears
SELECT object_name, SUM(rows_found) AS rows_found
FROM @results
GROUP BY object_name
ORDER BY object_name;
