/* Verify whether the erased phone number '+1-555-0000042' is still stored anywhere in llm_i6. */

DECLARE @subject_phone nvarchar(100) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

/* 1. dbo.customer: phone column was dropped, so it cannot contain the phone.
      Count matches in remaining columns only for completeness. */
INSERT INTO #results
SELECT 'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE CONVERT(nvarchar(max), customer_id) LIKE N'%' + @subject_phone + N'%'
   OR full_name LIKE N'%' + @subject_phone + N'%'
   OR email LIKE N'%' + @subject_phone + N'%';

/* 2. CDC change table cdc.dbo_customer_CT: captured_columns includes phone,
      so the phone value may still be present in the change table. */
IF OBJECT_ID(N'cdc.dbo_customer_CT') IS NOT NULL
BEGIN
    INSERT INTO #results
    SELECT 'cdc.dbo_customer_CT',
           COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE CONVERT(nvarchar(max), customer_id) LIKE N'%' + @subject_phone + N'%'
       OR full_name LIKE N'%' + @subject_phone + N'%'
       OR email LIKE N'%' + @subject_phone + N'%'
       OR CONVERT(nvarchar(max), phone) LIKE N'%' + @subject_phone + N'%';
END
ELSE
BEGIN
    INSERT INTO #results VALUES ('cdc.dbo_customer_CT', 0);
END

/* 3. Any other CDC capture instances / change tables in the database. */
DECLARE @schema sysname, @table sysname, @sql nvarchar(max);

DECLARE cdc_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM cdc.change_tables ct
    JOIN sys.tables t ON t.object_id = ct.source_object_id
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE NOT (s.name = 'dbo' AND t.name = 'customer');

OPEN cdc_cursor;
FETCH NEXT FROM cdc_cursor INTO @schema, @table;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
        INSERT INTO #results
        SELECT N''cdc.'' + ct.capture_instance + N''_CT'',
               COUNT(*)
        FROM cdc.' + QUOTENAME(@schema) + N'_' + QUOTENAME(@table) + N'_CT c
        WHERE CONVERT(nvarchar(max), c.customer_id) LIKE N''%'' + @p + N''%''
           OR c.full_name LIKE N''%'' + @p + N''%''
           OR c.email LIKE N''%'' + @p + N''%''
           OR CONVERT(nvarchar(max), c.phone) LIKE N''%'' + @p + N''%'';';
    BEGIN TRY
        EXEC sp_executesql @sql, N'@p nvarchar(100)', @p = @subject_phone;
    END TRY
    BEGIN CATCH
        INSERT INTO #results VALUES (N'cdc.' + @schema + N'_' + @table + N'_CT', 0);
    END CATCH
    FETCH NEXT FROM cdc_cursor INTO @schema, @table;
END
CLOSE cdc_cursor;
DEALLOCATE cdc_cursor;

/* 4. Temporal history tables (if any) that might contain a phone column. */
DECLARE @hist_schema sysname, @hist_table sysname, @hist_sql nvarchar(max);

DECLARE hist_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.temporal_type = 1;  /* history tables */

OPEN hist_cursor;
FETCH NEXT FROM hist_cursor INTO @hist_schema, @hist_table;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT 1 FROM sys.columns c
               WHERE c.object_id = OBJECT_ID(QUOTENAME(@hist_schema) + N'.' + QUOTENAME(@hist_table))
                 AND c.name = N'phone')
    BEGIN
        SET @hist_sql = N'
            INSERT INTO #results
            SELECT N''' + @hist_schema + N'.' + @hist_table + N''',
                   COUNT(*)
            FROM ' + QUOTENAME(@hist_schema) + N'.' + QUOTENAME(@hist_table) + N' h
            WHERE CONVERT(nvarchar(max), h.customer_id) LIKE N''%'' + @p + N''%''
               OR h.full_name LIKE N''%'' + @p + N''%''
               OR h.email LIKE N''%'' + @p + N''%''
               OR CONVERT(nvarchar(max), h.phone) LIKE N''%'' + @p + N''%'';';
        BEGIN TRY
            EXEC sp_executesql @hist_sql, N'@p nvarchar(100)', @p = @subject_phone;
        END TRY
        BEGIN CATCH
            INSERT INTO #results VALUES (@hist_schema + N'.' + @hist_table, 0);
        END CATCH
    END
    FETCH NEXT FROM hist_cursor INTO @hist_schema, @hist_table;
END
CLOSE hist_cursor;
DEALLOCATE hist_cursor;

/* 5. Scan all other user tables for any column that might contain the phone. */
DECLARE @tbl_schema sysname, @tbl_name sysname, @col_name sysname, @scan_sql nvarchar(max);

DECLARE scan_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, c.name
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    JOIN sys.columns c ON c.object_id = t.object_id
    WHERE t.is_ms_shipped = 0
      AND t.name NOT LIKE N'%_CT'
      AND s.name NOT IN (N'cdc')
      AND c.system_type_id IN (167, 231, 175, 239, 35, 99)  /* char/varchar/nchar/nvarchar/text/ntext */
      AND NOT (s.name = 'dbo' AND t.name = 'customer');

OPEN scan_cursor;
FETCH NEXT FROM scan_cursor INTO @tbl_schema, @tbl_name, @col_name;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @scan_sql = N'
        INSERT INTO #results
        SELECT N''' + @tbl_schema + N'.' + @tbl_name + N''',
               COUNT(*)
        FROM ' + QUOTENAME(@tbl_schema) + N'.' + QUOTENAME(@tbl_name) + N' x
        WHERE CONVERT(nvarchar(max), x.' + QUOTENAME(@col_name) + N') LIKE N''%'' + @p + N''%'';';
    BEGIN TRY
        EXEC sp_executesql @scan_sql, N'@p nvarchar(100)', @p = @subject_phone;
    END TRY
    BEGIN CATCH
        /* ignore unreadable objects */
    END CATCH
    FETCH NEXT FROM scan_cursor INTO @tbl_schema, @tbl_name, @col_name;
END
CLOSE scan_cursor;
DEALLOCATE scan_cursor;

/* Return exactly one result set. */
SELECT object_name, SUM(rows_found) AS rows_found
FROM #results
GROUP BY object_name
ORDER BY object_name;

DROP TABLE #results;
