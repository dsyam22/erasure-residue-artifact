/* Read-only verification: search the whole database for the subject's original personal data. */
DECLARE @cid int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

IF OBJECT_ID('tempdb..#scan') IS NOT NULL DROP TABLE #scan;
CREATE TABLE #scan (object_name sysname NOT NULL, rows_found bigint NOT NULL);

DECLARE @schema sysname, @table sysname, @col sysname, @sql nvarchar(max), @hit bigint;

DECLARE col_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, c.name
    FROM sys.columns AS c
    JOIN sys.tables  AS t ON t.object_id = c.object_id
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE c.system_type_id IN (
              SELECT system_type_id FROM sys.types
              WHERE name IN ('int','bigint','smallint','tinyint','nvarchar','nchar','varchar','char','text','ntext','sysname')
          )
      AND t.is_ms_shipped = 0
      AND t.name <> '#scan';

OPEN col_cursor;
FETCH NEXT FROM col_cursor INTO @schema, @table, @col;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
        SELECT @hit = COUNT_BIG(*)
        FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
        WHERE ' + QUOTENAME(@col) + N' = @p_val
           OR (' + QUOTENAME(@col) + N' IS NOT NULL AND CAST(' + QUOTENAME(@col) + N' AS nvarchar(max)) LIKE N''%'' + @p_val + N''%'');';

    IF EXISTS (SELECT 1 FROM sys.columns AS c2
               JOIN sys.types AS ty ON ty.user_type_id = c2.user_type_id
               WHERE c2.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
                 AND c2.name = @col
                 AND ty.name IN ('int','bigint','smallint','tinyint'))
    BEGIN
        -- numeric column: compare to customer_id only
        SET @sql = N'
            SELECT @hit = COUNT_BIG(*)
            FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
            WHERE ' + QUOTENAME(@col) + N' = @cid;';
        EXEC sp_executesql @sql, N'@cid int, @hit bigint OUTPUT', @cid = @cid, @hit = @hit OUTPUT;
    END
    ELSE
    BEGIN
        -- character column: test all three original string values
        SET @hit = 0;
        DECLARE @v nvarchar(200);
        DECLARE val_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT v FROM (VALUES (@full_name), (@email), (@phone)) AS x(v);
        OPEN val_cursor;
        FETCH NEXT FROM val_cursor INTO @v;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @h bigint;
            EXEC sp_executesql @sql, N'@p_val nvarchar(200), @hit bigint OUTPUT', @p_val = @v, @hit = @h OUTPUT;
            IF @h > @hit SET @hit = @h;
            FETCH NEXT FROM val_cursor INTO @v;
        END
        CLOSE val_cursor;
        DEALLOCATE val_cursor;
    END

    INSERT INTO #scan (object_name, rows_found)
    VALUES (QUOTENAME(@schema) + N'.' + QUOTENAME(@table), @hit);

    FETCH NEXT FROM col_cursor INTO @schema, @table, @col;
END

CLOSE col_cursor;
DEALLOCATE col_cursor;

SELECT object_name, SUM(rows_found) AS rows_found
FROM #scan
GROUP BY object_name
ORDER BY object_name;
