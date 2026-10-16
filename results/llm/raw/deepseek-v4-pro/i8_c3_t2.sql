DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255),
    rows_found int
);

-- Check the main customer table
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check CDC change tables (if any exist)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name LIKE '%_CT' AND is_tracked_by_cdc = 1)
BEGIN
    DECLARE @cdc_table nvarchar(255);
    DECLARE cdc_cursor CURSOR FOR
        SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.name LIKE '%_CT' AND t.is_tracked_by_cdc = 1;

    OPEN cdc_cursor;
    FETCH NEXT FROM cdc_cursor INTO @cdc_table;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql nvarchar(max) = N'INSERT INTO #results (object_name, rows_found) SELECT @obj, COUNT(*) FROM ' + @cdc_table + 
            N' WHERE customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph';
        EXEC sp_executesql @sql, N'@obj nvarchar(255), @cid int, @fn nvarchar(255), @em nvarchar(255), @ph nvarchar(255)',
            @obj = @cdc_table, @cid = @customer_id, @fn = @full_name, @em = @email, @ph = @phone;
        FETCH NEXT FROM cdc_cursor INTO @cdc_table;
    END;

    CLOSE cdc_cursor;
    DEALLOCATE cdc_cursor;
END

-- Check temporal history tables (if any exist)
IF EXISTS (SELECT 1 FROM sys.tables WHERE temporal_type = 1)
BEGIN
    DECLARE @hist_table nvarchar(255);
    DECLARE hist_cursor CURSOR FOR
        SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.temporal_type = 1;

    OPEN hist_cursor;
    FETCH NEXT FROM hist_cursor INTO @hist_table;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @hist_sql nvarchar(max) = N'INSERT INTO #results (object_name, rows_found) SELECT @obj, COUNT(*) FROM ' + @hist_table + 
            N' WHERE customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph';
        EXEC sp_executesql @hist_sql, N'@obj nvarchar(255), @cid int, @fn nvarchar(255), @em nvarchar(255), @ph nvarchar(255)',
            @obj = @hist_table, @cid = @customer_id, @fn = @full_name, @em = @email, @ph = @phone;
        FETCH NEXT FROM hist_cursor INTO @hist_table;
    END;

    CLOSE hist_cursor;
    DEALLOCATE hist_cursor;
END

-- Check any other user tables that might contain customer data (heuristic search)
DECLARE @other_table nvarchar(255);
DECLARE other_cursor CURSOR FOR
    SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name NOT IN ('customer')
      AND t.temporal_type = 0
      AND t.is_tracked_by_cdc = 0
      AND EXISTS (
          SELECT 1 FROM sys.columns c 
          WHERE c.object_id = t.object_id 
            AND (c.name IN ('customer_id','full_name','email','phone')
                 OR (c.name = 'customer_id' AND EXISTS (SELECT 1 FROM sys.columns c2 WHERE c2.object_id = t.object_id AND c2.name IN ('full_name','email','phone'))))
      );

OPEN other_cursor;
FETCH NEXT FROM other_cursor INTO @other_table;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @other_sql nvarchar(max) = N'INSERT INTO #results (object_name, rows_found) SELECT @obj, COUNT(*) FROM ' + @other_table + 
        N' WHERE customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph';
    EXEC sp_executesql @other_sql, N'@obj nvarchar(255), @cid int, @fn nvarchar(255), @em nvarchar(255), @ph nvarchar(255)',
        @obj = @other_table, @cid = @customer_id, @fn = @full_name, @em = @email, @ph = @phone;
    FETCH NEXT FROM other_cursor INTO @other_table;
END;

CLOSE other_cursor;
DEALLOCATE other_cursor;

-- Return results
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
