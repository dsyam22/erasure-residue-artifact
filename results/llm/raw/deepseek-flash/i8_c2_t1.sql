/* Read-only verification: is Subject_0000042 personal data still stored anywhere? */

DECLARE @cid   int           = 42;
DECLARE @name  nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname NOT NULL, rows_found bigint NOT NULL);

/* ---- dbo.customer -------------------------------------------------- */
IF OBJECT_ID(N'dbo.customer', N'U') IS NOT NULL
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer', COUNT(*)
    FROM dbo.customer
    WHERE customer_id = @cid
       OR full_name = @name
       OR email     = @email
       OR phone     = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found) VALUES (N'dbo.customer', 0);
END

/* ---- dbo.customer history (only if temporal) ----------------------- */
IF EXISTS (SELECT 1 FROM sys.tables t WHERE t.object_id = OBJECT_ID(N'dbo.customer') AND t.temporal_type <> 0)
BEGIN
    IF OBJECT_ID(N'dbo.customer_history', N'U') IS NOT NULL
    BEGIN
        INSERT INTO #results (object_name, rows_found)
        SELECT N'dbo.customer_history', COUNT(*)
        FROM dbo.customer_history
        WHERE customer_id = @cid
           OR full_name = @name
           OR email     = @email
           OR phone     = @phone;
    END
    ELSE
    BEGIN
        INSERT INTO #results (object_name, rows_found) VALUES (N'dbo.customer_history', 0);
    END
END

/* ---- CDC capture instances ----------------------------------------- */
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = DB_NAME() AND is_cdc_enabled = 1)
BEGIN
    DECLARE @cap sysname, @sch sysname, @tbl sysname, @sql nvarchar(max);

    DECLARE cdc_cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT capture_instance, OBJECT_SCHEMA_NAME(source_object_id), OBJECT_NAME(source_object_id)
        FROM cdc.change_tables;

    OPEN cdc_cur;
    FETCH NEXT FROM cdc_cur INTO @cap, @sch, @tbl;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @sch = N'dbo' AND @tbl = N'customer'
        BEGIN
            SET @sql = N'
                INSERT INTO #results (object_name, rows_found)
                SELECT N''cdc.'' + @cap, COUNT(*)
                FROM ' + QUOTENAME(N'cdc') + N'.' + QUOTENAME(@cap) + N' AS c
                WHERE c.customer_id = @cid
                   OR c.full_name = @name
                   OR c.email     = @email
                   OR c.phone     = @phone;';

            EXEC sp_executesql @sql,
                 N'@cap sysname, @cid int, @name nvarchar(200), @email nvarchar(200), @phone nvarchar(200)',
                 @cap = @cap, @cid = @cid, @name = @name, @email = @email, @phone = @phone;
        END

        FETCH NEXT FROM cdc_cur INTO @cap, @sch, @tbl;
    END

    CLOSE cdc_cur;
    DEALLOCATE cdc_cur;
END

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
