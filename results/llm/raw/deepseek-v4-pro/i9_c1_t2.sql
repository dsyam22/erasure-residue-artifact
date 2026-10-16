SET NOCOUNT ON;

DECLARE @CustomerId int = 42;
DECLARE @FullName nvarchar(255) = N'Subject_0000042';
DECLARE @Email nvarchar(255) = N'subject42@example.invalid';
DECLARE @Phone nvarchar(255) = N'+1-555-0000042';

CREATE TABLE #Results (
    object_name nvarchar(255) NOT NULL,
    rows_found bigint NOT NULL
);

-- Check dbo.customer
INSERT INTO #Results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = @CustomerId
   OR full_name = @FullName
   OR email = @Email
   OR phone = @Phone;

-- Check all other user tables for columns that could contain personal data
DECLARE @TableSchema nvarchar(128);
DECLARE @TableName nvarchar(128);
DECLARE @ColumnName nvarchar(128);
DECLARE @Sql nvarchar(max);

DECLARE table_cursor CURSOR FOR
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE ty.name IN ('nvarchar', 'varchar', 'nchar', 'char', 'ntext', 'text', 'sysname')
  AND NOT (s.name = 'dbo' AND t.name = 'customer')
ORDER BY s.name, t.name, c.name;

DECLARE @CurrentTable nvarchar(255);
DECLARE @PreviousTable nvarchar(255) = N'';

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @TableSchema, @TableName, @ColumnName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @CurrentTable = QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableName);
    
    IF @CurrentTable <> @PreviousTable
    BEGIN
        -- Remove previous table's result if exists
        IF @PreviousTable <> N''
        BEGIN
            -- Keep the max rows_found for this table
            ;WITH cte AS (
                SELECT object_name, MAX(rows_found) AS max_rows
                FROM #Results
                WHERE object_name = @PreviousTable
                GROUP BY object_name
            )
            UPDATE r
            SET r.rows_found = cte.max_rows
            FROM #Results r
            JOIN cte ON r.object_name = cte.object_name;
            
            -- Delete duplicates keeping one row per table
            ;WITH cte AS (
                SELECT *, ROW_NUMBER() OVER (PARTITION BY object_name ORDER BY rows_found DESC) AS rn
                FROM #Results
                WHERE object_name = @PreviousTable
            )
            DELETE FROM cte WHERE rn > 1;
        END
        
        SET @PreviousTable = @CurrentTable;
    END
    
    SET @Sql = N'
        INSERT INTO #Results (object_name, rows_found)
        SELECT 
            ''' + @CurrentTable + N''',
            COUNT(*)
        FROM ' + @CurrentTable + N'
        WHERE ' + QUOTENAME(@ColumnName) + N' = @FullName
           OR ' + QUOTENAME(@ColumnName) + N' = @Email
           OR ' + QUOTENAME(@ColumnName) + N' = @Phone
           OR (' + QUOTENAME(@ColumnName) + N' LIKE ''%'' + @FullName + ''%'' AND ' + QUOTENAME(@ColumnName) + N' IS NOT NULL)
           OR (' + QUOTENAME(@ColumnName) + N' LIKE ''%'' + @Email + ''%'' AND ' + QUOTENAME(@ColumnName) + N' IS NOT NULL)
           OR (' + QUOTENAME(@ColumnName) + N' LIKE ''%'' + @Phone + ''%'' AND ' + QUOTENAME(@ColumnName) + N' IS NOT NULL)
    ';
    
    BEGIN TRY
        EXEC sp_executesql @Sql, N'@FullName nvarchar(255), @Email nvarchar(255), @Phone nvarchar(255)', 
            @FullName = @FullName, @Email = @Email, @Phone = @Phone;
    END TRY
    BEGIN CATCH
        -- Skip if table doesn't exist or other errors
    END CATCH
    
    FETCH NEXT FROM table_cursor INTO @TableSchema, @TableName, @ColumnName;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Final cleanup: consolidate results to one row per table with max rows_found
IF @PreviousTable <> N''
BEGIN
    ;WITH cte AS (
        SELECT object_name, MAX(rows_found) AS max_rows
        FROM #Results
        WHERE object_name = @PreviousTable
        GROUP BY object_name
    )
    UPDATE r
    SET r.rows_found = cte.max_rows
    FROM #Results r
    JOIN cte ON r.object_name = cte.object_name;
    
    ;WITH cte AS (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY object_name ORDER BY rows_found DESC) AS rn
        FROM #Results
        WHERE object_name = @PreviousTable
    )
    DELETE FROM cte WHERE rn > 1;
END

-- Ensure dbo.customer is included even if no rows found
IF NOT EXISTS (SELECT 1 FROM #Results WHERE object_name = N'dbo.customer')
    INSERT INTO #Results (object_name, rows_found) VALUES (N'dbo.customer', 0);

-- Consolidate all duplicates, keeping max rows_found per table
;WITH cte AS (
    SELECT object_name, MAX(rows_found) AS max_rows
    FROM #Results
    GROUP BY object_name
)
DELETE r
FROM #Results r
JOIN cte ON r.object_name = cte.object_name
WHERE r.rows_found <> cte.max_rows;

;WITH cte AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY object_name ORDER BY rows_found DESC) AS rn
    FROM #Results
)
DELETE FROM cte WHERE rn > 1;

-- Return final result
SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;

DROP TABLE #Results;
