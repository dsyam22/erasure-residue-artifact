SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @phone nvarchar(100) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found int);

/* 1. dbo.customer - phone column was dropped, so it cannot be checked here.
      We still report the object with 0 since the column no longer exists. */
INSERT INTO @results (object_name, rows_found)
VALUES ('dbo.customer', 0);

/* 2. CDC change table cdc.dbo_customer_CT - captured_columns included phone.
      Check whether the phone value is still present in the CDC change table.
      The column may or may not still exist; use dynamic SQL guarded by metadata. */
DECLARE @cdcExists bit = 0;
IF OBJECT_ID('cdc.dbo_customer_CT') IS NOT NULL
    SET @cdcExists = 1;

IF @cdcExists = 1
BEGIN
    DECLARE @hasPhone bit = 0;
    IF EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID('cdc.dbo_customer_CT')
          AND name = 'phone'
    )
        SET @hasPhone = 1;

    IF @hasPhone = 1
    BEGIN
        DECLARE @sql nvarchar(max) = N'
            INSERT INTO @results (object_name, rows_found)
            SELECT ''cdc.dbo_customer_CT'', COUNT(*)
            FROM cdc.dbo_customer_CT
            WHERE phone = @p;';
        EXEC sp_executesql @sql,
            N'@p nvarchar(100)',
            @p = @phone;
    END
    ELSE
    BEGIN
        INSERT INTO @results (object_name, rows_found)
        VALUES ('cdc.dbo_customer_CT', 0);
    END
END
ELSE
BEGIN
    INSERT INTO @results (object_name, rows_found)
    VALUES ('cdc.dbo_customer_CT', 0);
END

/* 3. Scan every other user table/column in the database for the phone value.
      This covers any table that may still store the phone number. */
DECLARE @schema sysname, @table sysname, @column sysname;
DECLARE @dynSql nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, c.name
    FROM sys.columns c
    JOIN sys.tables t ON t.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
      AND c.system_type_id IN (167, 231, 175, 239) /* varchar, nvarchar, char, nchar */
      AND NOT (s.name = 'dbo' AND t.name = 'customer')
      AND NOT (s.name = 'cdc' AND t.name = 'dbo_customer_CT');

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table, @column;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @dynSql = N'
        INSERT INTO @results (object_name, rows_found)
        SELECT @obj, COUNT(*)
        FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
        WHERE ' + QUOTENAME(@column) + N' = @p;';

    EXEC sp_executesql @dynSql,
        N'@obj sysname, @p nvarchar(100)',
        @obj = @schema + N'.' + @table,
        @p = @phone;

    FETCH NEXT FROM cur INTO @schema, @table, @column;
END

CLOSE cur;
DEALLOCATE cur;

/* Aggregate: keep one row per object, summing matches across columns. */
SELECT object_name, SUM(rows_found) AS rows_found
FROM @results
GROUP BY object_name
ORDER BY object_name;
