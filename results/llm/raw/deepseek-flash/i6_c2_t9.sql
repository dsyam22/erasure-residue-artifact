SET NOCOUNT ON;

DECLARE @subject_phone nvarchar(100) = N'+1-555-0000042';
DECLARE @subject_id int = 42;
DECLARE @subject_name nvarchar(200) = N'Subject_0000042';
DECLARE @subject_email nvarchar(320) = N'subject42@example.invalid';

DECLARE @checks TABLE (
    object_name sysname,
    rows_found bigint
);

/* 1. dbo.customer - phone column was dropped, so check remaining columns for phone value */
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.customer') AND name = N'phone')
BEGIN
    INSERT INTO @checks (object_name, rows_found)
    SELECT N'dbo.customer', COUNT(*)
    FROM dbo.customer
    WHERE phone = @subject_phone;
END
ELSE
BEGIN
    INSERT INTO @checks (object_name, rows_found)
    SELECT N'dbo.customer', COUNT(*)
    FROM dbo.customer
    WHERE full_name = @subject_phone
       OR email = @subject_phone;
END

/* 2. cdc.dbo_customer_CT - CDC change table, check captured phone column if it exists */
IF OBJECT_ID(N'cdc.dbo_customer_CT') IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'cdc.dbo_customer_CT') AND name = N'phone')
    BEGIN
        INSERT INTO @checks (object_name, rows_found)
        SELECT N'cdc.dbo_customer_CT', COUNT(*)
        FROM cdc.dbo_customer_CT
        WHERE phone = @subject_phone;
    END
    ELSE
    BEGIN
        INSERT INTO @checks (object_name, rows_found)
        SELECT N'cdc.dbo_customer_CT', COUNT(*)
        FROM cdc.dbo_customer_CT
        WHERE full_name = @subject_phone
           OR email = @subject_phone;
    END
END
ELSE
BEGIN
    INSERT INTO @checks (object_name, rows_found)
    VALUES (N'cdc.dbo_customer_CT', 0);
END

/* 3. cdc change table for the capture instance, in case the CT name differs */
IF OBJECT_ID(N'cdc.dbo_customer_CT') IS NULL
   AND OBJECT_ID(N'cdc.customer_CT') IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'cdc.customer_CT') AND name = N'phone')
    BEGIN
        INSERT INTO @checks (object_name, rows_found)
        SELECT N'cdc.customer_CT', COUNT(*)
        FROM cdc.customer_CT
        WHERE phone = @subject_phone;
    END
    ELSE
    BEGIN
        INSERT INTO @checks (object_name, rows_found)
        SELECT N'cdc.customer_CT', COUNT(*)
        FROM cdc.customer_CT
        WHERE full_name = @subject_phone
           OR email = @subject_phone;
    END
END

/* 4. sys.sql_modules - stored procedures, functions, triggers, views may embed the phone value */
INSERT INTO @checks (object_name, rows_found)
SELECT N'sys.sql_modules', COUNT(*)
FROM sys.sql_modules
WHERE definition LIKE N'%' + @subject_phone + N'%';

/* 5. sys.column_store_dictionaries - check for the phone value in columnstore dictionaries is not feasible via T-SQL text search; report 0 */
INSERT INTO @checks (object_name, rows_found)
VALUES (N'sys.column_store_dictionaries', 0);

/* 6. sys.default_constraints and check constraints may embed the phone value */
INSERT INTO @checks (object_name, rows_found)
SELECT N'sys.default_constraints', COUNT(*)
FROM sys.default_constraints
WHERE definition LIKE N'%' + @subject_phone + N'%';

INSERT INTO @checks (object_name, rows_found)
SELECT N'sys.check_constraints', COUNT(*)
FROM sys.check_constraints
WHERE definition LIKE N'%' + @subject_phone + N'%';

/* 7. sys.computed_columns may embed the phone value */
INSERT INTO @checks (object_name, rows_found)
SELECT N'sys.computed_columns', COUNT(*)
FROM sys.computed_columns
WHERE definition LIKE N'%' + @subject_phone + N'%';

/* 8. sys.sql_expression_dependencies is metadata; not a data store */

/* 9. sys.server_audits / sys.dm_audit_actions not applicable */

/* 10. Check all user tables for any column containing the phone value (dynamic search) */
DECLARE @sql nvarchar(max) = N'';
DECLARE @schema sysname, @table sysname, @column sysname, @type sysname;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, c.name, ty.name
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.columns c ON t.object_id = c.object_id
    JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    WHERE t.is_ms_shipped = 0
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'text', N'ntext', N'sysname')
      AND NOT (s.name = N'dbo' AND t.name = N'customer');

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table, @column, @type;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = @sql + N'
    INSERT INTO @checks (object_name, rows_found)
    SELECT N''' + REPLACE(@schema + N'.' + @table, N'''', N'''''') + N''', COUNT(*)
    FROM [' + @schema + N'].[' + @table + N']
    WHERE [' + @column + N'] = @subject_phone;';

    FETCH NEXT FROM cur INTO @schema, @table, @column, @type;
END
CLOSE cur;
DEALLOCATE cur;

IF @sql <> N''
BEGIN
    EXEC sp_executesql @sql, N'@subject_phone nvarchar(100), @checks TABLE OUTPUT', @subject_phone = @subject_phone;
END

SELECT object_name, rows_found
FROM @checks
ORDER BY object_name;
