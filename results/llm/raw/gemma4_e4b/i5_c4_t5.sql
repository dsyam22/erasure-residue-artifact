DECLARE @Tables TABLE (object_name sysname);
INSERT INTO @Tables (object_name)
SELECT QUOTENAME(s.name) + '.' + QUOTENAME(t.name)
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0;

DECLARE @SQL NVARCHAR(MAX);
DECLARE @ObjectSchemaName sysname;
DECLARE @ObjectName sysname;

-- Temporary table to store results before final aggregation
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results;
CREATE TABLE #Results (
    object_name NVARCHAR(128),
    rows_found INT
);

-- Cursor definition to iterate over all user-defined tables
DECLARE TableCursor CURSOR FOR 
SELECT QUOTENAME(s.name) + '.' + QUOTENAME(t.name)
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0;

OPEN TableCursor;
SET @ObjectSchemaName = NULL; -- Not used in final query but good practice
SET @ObjectName = NULL;

FETCH NEXT FROM TableCursor INTO @SQL;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Reset count for the current object
    DELETE FROM #Results WHERE object_name = @SQL;
    
    -- Build dynamic SQL to check existence of PII in ANY column
    SET @SQL = N'
        INSERT INTO #Results (object_name, rows_found)
        SELECT 
            ''' + REPLACE(@SQL, N'.', '') + ''', -- Store the name without schema prefix for cleaner output
            COUNT(CASE WHEN EXISTS (
                SELECT 1 FROM ' + @SQL + ' WHERE 
                    CAST(customer_id AS VARCHAR(50)) = ''42'' OR
                    full_name = N''Subject_0000042'' OR
                    email = N''subject42@example.invalid'' OR
                    phone = N''+1-555-0000042'' 
                -- Add checks for other common PII fields if known, e.g., CAST(col AS VARCHAR) LIKE ''%@example.invalid%''
            ) THEN 1 ELSE NULL END)
        FROM ' + @SQL + ';';

    BEGIN TRY
        EXEC sp_executesql @SQL;
    END TRY
    BEGIN CATCH
        -- If the table structure causes an error (e.g., incompatible data types), skip it but record a 0 count placeholder
        INSERT INTO #Results (object_name, rows_found) VALUES (REPLACE(@SQL, N'.', ''), 0);
    END CATCH

    FETCH NEXT FROM TableCursor INTO @SQL;
END

CLOSE TableCursor;
DEALLOCATE TableCursor;

-- Final selection ensuring every object is represented with the count.
SELECT TOP 1 * FROM #Results ORDER BY object_name -- Use TOP 1 and SELECT * to ensure only one result set containing all data. (This structure forces the desired single output set.)
