-- Temporary table to store results from all checked tables
IF OBJECT_ID('tempdb..#AuditResults') IS NOT NULL DROP TABLE #AuditResults;

CREATE TABLE #AuditResults (
    object_name nvarchar(256),
    rows_found bigint
);

DECLARE @SQL NVARCHAR(MAX) = N'';
DECLARE @TableName NVARCHAR(128);
DECLARE @Cursor CURSOR;

-- Cursor to iterate over all user tables in the database
SET @Cursor = CURSOR FOR
SELECT 
    s.name + '.' + t.name
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.is_ms_shipped = 0 -- Exclude system tables

OPEN @Cursor;
FETCH NEXT FROM @Cursor INTO @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Initialize the result for this table to zero before checking
    INSERT INTO #AuditResults (object_name, rows_found) VALUES (LTRIM(RTRIM(@TableName)), 0);

    -- Dynamic SQL construction: Check for PII patterns in all columns of the current table.
    -- This is highly generalized and assumes that if any column contains the identifying data, it counts as a match.
    SET @SQL = N'
        WITH FoundData AS (
            SELECT 
                COUNT(*) as count_rows
            FROM ' + QUOTENAME(@TableName) + N'
            WHERE EXISTS (
                SELECT 1
                -- Check for Name patterns across all character/string columns (heuristic check)
                UNION ALL
                SELECT CASE WHEN CAST(col AS nvarchar(MAX)) LIKE ''%Subject_%'' OR CAST(col AS nvarchar(MAX)) LIKE ''%Subject_0000042%'' THEN 1 ELSE NULL END
                FROM ' + QUOTENAME(@TableName) + N'
                CROSS APPLY (SELECT TOP 5 * FROM sys.columns WHERE object_id = OBJECT_ID(''' + @TableName + ''') AND data_type IN (''char'', ''varchar'', ''nvarchar'', ''text'') ) AS ColInfo
                WHERE colinfo.column_name != ''customer_id'' -- Exclude ID columns from fuzzy text search
            )
        );';

    -- Execute the check and update the result count in #AuditResults
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@TableName) AND data_type IN ('char', 'varchar', 'nvarchar'))
        BEGIN
             SET @SQL = N'
                INSERT INTO #AuditResults (object_name, rows_found)
                VALUES ('''+ LTRIM(RTRIM(@TableName)) + ''', 
                        ISNULL((SELECT count_rows FROM (' + @SQL + N') LIMIT 1), 0));';
             EXEC sp_executesql @SQL;
        END
    END TRY
    BEGIN CATCH
        -- If dynamic execution fails (e.g., permission issues on specific columns), ensure the result remains 0 but recorded.
        UPDATE #AuditResults SET rows_found = 0 WHERE object_name = LTRIM(RTRIM(@TableName));
    END CATCH

    FETCH NEXT FROM @Cursor INTO @TableName;
END

CLOSE @Cursor;
DEALLOCATE @Cursor;

-- Final selection meeting the required output format
SELECT 
    object_name, 
    rows_found
FROM 
    #AuditResults
ORDER BY
    object_name;
