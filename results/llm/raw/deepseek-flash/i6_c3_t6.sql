/* Read-only verification: is Subject_0000042's phone number still stored anywhere? */

DECLARE @phone nvarchar(100) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found int);

/* 1. Base table dbo.customer (phone column was dropped) */
IF COL_LENGTH('dbo.customer', 'phone') IS NOT NULL
    INSERT INTO @results
    SELECT 'dbo.customer', COUNT(*)
    FROM dbo.customer
    WHERE CAST(phone AS nvarchar(max)) = @phone;
ELSE
    INSERT INTO @results VALUES ('dbo.customer', 0);

/* 2. CDC change table cdc.dbo_customer_CT */
IF OBJECT_ID('cdc.dbo_customer_CT') IS NOT NULL
    INSERT INTO @results
    SELECT 'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE CAST(phone AS nvarchar(max)) = @phone;
ELSE
    INSERT INTO @results VALUES ('cdc.dbo_customer_CT', 0);

/* 3. Any other CDC capture instances' change tables that might carry a phone column */
DECLARE @tbl sysname, @sch sysname, @sql nvarchar(max);

DECLARE cdc_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT OBJECT_SCHEMA_NAME(ct.object_id), OBJECT_NAME(ct.object_id)
    FROM cdc.change_tables ct
    WHERE ct.object_id <> OBJECT_ID('cdc.dbo_customer_CT');

OPEN cdc_cur;
FETCH NEXT FROM cdc_cur INTO @sch, @tbl;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF COL_LENGTH(QUOTENAME(@sch) + '.' + QUOTENAME(@tbl), 'phone') IS NOT NULL
    BEGIN
        SET @sql = N'INSERT INTO @results SELECT ' + QUOTENAME(@sch + '.' + @tbl, '''') +
                   N', COUNT(*) FROM ' + QUOTENAME(@sch) + '.' + QUOTENAME(@tbl) +
                   N' WHERE CAST(phone AS nvarchar(max)) = @p;';
        EXEC sp_executesql @sql, N'@p nvarchar(100)', @p = @phone;
    END
    ELSE
        INSERT INTO @results VALUES (@sch + '.' + @tbl, 0);

    FETCH NEXT FROM cdc_cur INTO @sch, @tbl;
END
CLOSE cdc_cur;
DEALLOCATE cdc_cur;

/* 4. System-versioned temporal history tables on the customer table (if any) */
IF OBJECT_ID('dbo.customer', 'U') IS NOT NULL
BEGIN
    DECLARE @hist sysname;
    SELECT @hist = OBJECT_SCHEMA_NAME(history_table_id) + '.' + OBJECT_NAME(history_table_id)
    FROM sys.tables
    WHERE object_id = OBJECT_ID('dbo.customer')
      AND temporal_type = 2; /* SYSTEM_VERSIONED_TEMPORAL_TABLE */

    IF @hist IS NOT NULL
    BEGIN
        IF COL_LENGTH(@hist, 'phone') IS NOT NULL
        BEGIN
            SET @sql = N'INSERT INTO @results SELECT ' + QUOTENAME(@hist, '''') +
                       N', COUNT(*) FROM ' + @hist +
                       N' WHERE CAST(phone AS nvarchar(max)) = @p;';
            EXEC sp_executesql @sql, N'@p nvarchar(100)', @p = @phone;
        END
        ELSE
            INSERT INTO @results VALUES (@hist, 0);
    END
END

/* 5. Scan all other user tables for any column named like phone / phone_number / telephone */
DECLARE @t2 sysname, @s2 sysname, @c2 sysname;
DECLARE col_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, c.name
    FROM sys.columns c
    JOIN sys.tables t ON t.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
      AND c.name IN ('phone', 'phone_number', 'telephone', 'phone_no', 'mobile')
      AND NOT (s.name = 'dbo' AND t.name = 'customer')
      AND NOT (s.name = 'cdc');

OPEN col_cur;
FETCH NEXT FROM col_cur INTO @s2, @t2, @c2;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'INSERT INTO @results SELECT ' + QUOTENAME(@s2 + '.' + @t2, '''') +
               N', COUNT(*) FROM ' + QUOTENAME(@s2) + '.' + QUOTENAME(@t2) +
               N' WHERE CAST(' + QUOTENAME(@c2) + N' AS nvarchar(max)) = @p;';
    EXEC sp_executesql @sql, N'@p nvarchar(100)', @p = @phone;

    FETCH NEXT FROM col_cur INTO @s2, @t2, @c2;
END
CLOSE col_cur;
DEALLOCATE col_cur;

/* 6. Full-text / audit style search across all string columns in user tables (catch copies under other names) */
DECLARE @t3 sysname, @s3 sysname, @c3 sysname;
DECLARE str_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, c.name
    FROM sys.columns c
    JOIN sys.tables t ON t.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    JOIN sys.types ty ON ty.user_type_id = c.user_type_id
    WHERE t.is_ms_shipped = 0
      AND ty.name IN ('nvarchar', 'varchar', 'nchar', 'char', 'ntext', 'text')
      AND c.name NOT IN ('phone', 'phone_number', 'telephone', 'phone_no', 'mobile')
      AND NOT (s.name = 'dbo' AND t.name = 'customer')
      AND NOT (s.name = 'cdc');

OPEN str_cur;
FETCH NEXT FROM str_cur INTO @s3, @t3, @c3;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'INSERT INTO @results SELECT ' + QUOTENAME(@s3 + '.' + @t3, '''') +
               N', COUNT(*) FROM ' + QUOTENAME(@s3) + '.' + QUOTENAME(@t3) +
               N' WHERE CAST(' + QUOTENAME(@c3) + N' AS nvarchar(max)) LIKE ''%'' + @p + ''%'';';
    EXEC sp_executesql @sql, N'@p nvarchar(100)', @p = @phone;

    FETCH NEXT FROM str_cur INTO @s3, @t3, @c3;
END
CLOSE str_cur;
DEALLOCATE str_cur;

/* Return exactly one result set */
SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
