SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(255) = N'+1-555-0000042';

CREATE TABLE #Results (
    object_name nvarchar(255) NOT NULL,
    rows_found int NOT NULL
);

-- Check dbo.customer
INSERT INTO #Results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check all user tables for columns that might contain the subject's personal data
DECLARE @sql nvarchar(max);
DECLARE @table_name nvarchar(255);
DECLARE @schema_name nvarchar(255);

DECLARE table_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT 
    s.name AS schema_name,
    t.name AS table_name
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
  AND NOT (s.name = 'dbo' AND t.name = 'customer'); -- already checked

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @full_table_name nvarchar(255) = QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name);
    
    SET @sql = N'
        IF EXISTS (
            SELECT 1
            FROM sys.columns c
            WHERE c.object_id = OBJECT_ID(''' + @full_table_name + N''')
              AND (
                  c.name IN (''customer_id'', ''full_name'', ''email'', ''phone'')
                  OR c.system_type_id IN (167, 175, 231, 239) -- varchar, nvarchar, char, nchar
              )
        )
        BEGIN
            DECLARE @count int = 0;
            DECLARE @where_clause nvarchar(max) = N'''';
            
            IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @full_table_name + N''') AND name = ''customer_id'')
                SET @where_clause = @where_clause + N'' OR customer_id = @customer_id'';
            
            IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @full_table_name + N''') AND name = ''full_name'')
                SET @where_clause = @where_clause + N'' OR full_name = @full_name'';
            
            IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @full_table_name + N''') AND name = ''email'')
                SET @where_clause = @where_clause + N'' OR email = @email'';
            
            IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @full_table_name + N''') AND name = ''phone'')
                SET @where_clause = @where_clause + N'' OR phone = @phone'';
            
            IF LEN(@where_clause) > 0
            BEGIN
                SET @where_clause = STUFF(@where_clause, 1, 4, N'' WHERE '');
                SET @sql = N''SELECT @count = COUNT(*) FROM '' + ''' + @full_table_name + N''' + @where_clause;
                EXEC sp_executesql @sql, N''@customer_id int, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(255), @count int OUTPUT'', @customer_id, @full_name, @email, @phone, @count OUTPUT;
            END
            
            INSERT INTO #Results (object_name, rows_found)
            VALUES (''' + @full_table_name + N''', @count);
        END
    ';
    
    BEGIN TRY
        EXEC sp_executesql @sql, N'@customer_id int, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(255)', @customer_id, @full_name, @email, @phone;
    END TRY
    BEGIN CATCH
        -- If table doesn't exist or other error, skip
    END CATCH
    
    FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return results
SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;

DROP TABLE #Results;
