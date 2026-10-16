DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(255) = N'+1-555-0000042';

CREATE TABLE #results (object_name nvarchar(255), rows_found int);

-- Check base table
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
    DECLARE @ct_table nvarchar(255);
    DECLARE ct_cursor CURSOR FOR
        SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.name LIKE '%_CT'
          AND t.is_tracked_by_cdc = 1;

    OPEN ct_cursor;
    FETCH NEXT FROM ct_cursor INTO @ct_table;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql nvarchar(max) = N'SELECT @cnt = COUNT(*) FROM ' + @ct_table + N' WHERE __$operation IN (1,2,3,4) AND (';
        DECLARE @has_col bit = 0;

        -- Check if columns exist in CT table
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@ct_table) AND name = 'customer_id')
        BEGIN
            SET @sql = @sql + N'customer_id = @customer_id';
            SET @has_col = 1;
        END
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@ct_table) AND name = 'full_name')
        BEGIN
            IF @has_col = 1 SET @sql = @sql + N' OR ';
            SET @sql = @sql + N'full_name = @full_name';
            SET @has_col = 1;
        END
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@ct_table) AND name = 'email')
        BEGIN
            IF @has_col = 1 SET @sql = @sql + N' OR ';
            SET @sql = @sql + N'email = @email';
            SET @has_col = 1;
        END
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@ct_table) AND name = 'phone')
        BEGIN
            IF @has_col = 1 SET @sql = @sql + N' OR ';
            SET @sql = @sql + N'phone = @phone';
            SET @has_col = 1;
        END

        IF @has_col = 1
        BEGIN
            SET @sql = @sql + N')';
            DECLARE @cnt int = 0;
            EXEC sp_executesql @sql, N'@customer_id int, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(255), @cnt int OUTPUT', 
                @customer_id = @customer_id, @full_name = @full_name, @email = @email, @phone = @phone, @cnt = @cnt OUTPUT;
            INSERT INTO #results (object_name, rows_found) VALUES (@ct_table, @cnt);
        END

        FETCH NEXT FROM ct_cursor INTO @ct_table;
    END

    CLOSE ct_cursor;
    DEALLOCATE ct_cursor;
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
        DECLARE @hist_sql nvarchar(max) = N'SELECT @cnt = COUNT(*) FROM ' + @hist_table + N' WHERE ';
        DECLARE @hist_has_col bit = 0;

        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@hist_table) AND name = 'customer_id')
        BEGIN
            SET @hist_sql = @hist_sql + N'customer_id = @customer_id';
            SET @hist_has_col = 1;
        END
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@hist_table) AND name = 'full_name')
        BEGIN
            IF @hist_has_col = 1 SET @hist_sql = @hist_sql + N' OR ';
            SET @hist_sql = @hist_sql + N'full_name = @full_name';
            SET @hist_has_col = 1;
        END
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@hist_table) AND name = 'email')
        BEGIN
            IF @hist_has_col = 1 SET @hist_sql = @hist_sql + N' OR ';
            SET @hist_sql = @hist_sql + N'email = @email';
            SET @hist_has_col = 1;
        END
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@hist_table) AND name = 'phone')
        BEGIN
            IF @hist_has_col = 1 SET @hist_sql = @hist_sql + N' OR ';
            SET @hist_sql = @hist_sql + N'phone = @phone';
            SET @hist_has_col = 1;
        END

        IF @hist_has_col = 1
        BEGIN
            DECLARE @hist_cnt int = 0;
            EXEC sp_executesql @hist_sql, N'@customer_id int, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(255), @cnt int OUTPUT', 
                @customer_id = @customer_id, @full_name = @full_name, @email = @email, @phone = @phone, @cnt = @hist_cnt OUTPUT;
            INSERT INTO #results (object_name, rows_found) VALUES (@hist_table, @hist_cnt);
        END

        FETCH NEXT FROM hist_cursor INTO @hist_table;
    END

    CLOSE hist_cursor;
    DEALLOCATE hist_cursor;
END

-- Return results
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
