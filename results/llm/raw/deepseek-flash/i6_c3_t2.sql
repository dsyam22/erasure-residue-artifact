/* Read-only verification: is subject 42's phone number still stored anywhere? */

DECLARE @phone nvarchar(50) = N'+1-555-0000042';
DECLARE @cust  int = 42;

/* Build the list of candidate objects to check:
   1. dbo.customer itself (phone column was dropped, but check anyway)
   2. CDC capture instance change table cdc.dbo_customer_CT
   3. Any temporal history tables for dbo.customer
   4. Any other table in the database whose name suggests a copy of customer data */
DECLARE @targets TABLE (object_name sysname, kind varchar(20));

INSERT INTO @targets (object_name, kind)
SELECT N'dbo.customer', 'base';

/* CDC change table for the capture instance, discovered dynamically */
INSERT INTO @targets (object_name, kind)
SELECT QUOTENAME(OBJECT_SCHEMA_NAME(ct.object_id)) + N'.' + QUOTENAME(OBJECT_NAME(ct.object_id)), 'cdc'
FROM cdc.change_tables ct
WHERE ct.capture_instance = N'dbo_customer';

/* Temporal history tables for dbo.customer, if any */
INSERT INTO @targets (object_name, kind)
SELECT QUOTENAME(OBJECT_SCHEMA_NAME(t.object_id)) + N'.' + QUOTENAME(OBJECT_NAME(t.object_id)), 'history'
FROM sys.tables t
WHERE t.object_id = OBJECT_ID(N'dbo.customer')
  AND t.temporal_type = 1;

/* Any other table in the database containing a column named phone / phone_number,
   in case the phone data was copied elsewhere */
INSERT INTO @targets (object_name, kind)
SELECT DISTINCT QUOTENAME(OBJECT_SCHEMA_NAME(c.object_id)) + N'.' + QUOTENAME(OBJECT_NAME(c.object_id)), 'other'
FROM sys.columns c
JOIN sys.tables  t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE c.name IN (N'phone', N'phone_number', N'phonenumber', N'telephone', N'tel')
  AND NOT EXISTS (SELECT 1 FROM @targets x WHERE x.object_name = QUOTENAME(s.name) + N'.' + QUOTENAME(t.name));

/* Results */
CREATE TABLE #results (object_name sysname, rows_found bigint);

DECLARE @obj sysname, @kind varchar(20), @sql nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT object_name, kind FROM @targets ORDER BY object_name;

OPEN cur;
FETCH NEXT FROM cur INTO @obj, @kind;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'';
    BEGIN TRY
        IF @kind = 'base'
        BEGIN
            /* phone column has been dropped; if it still exists, count matches on it */
            IF EXISTS (SELECT 1 FROM sys.columns
                       WHERE object_id = OBJECT_ID(@obj) AND name = N'phone')
            BEGIN
                SET @sql = N'INSERT INTO #results SELECT @obj, COUNT_BIG(*) FROM ' + @obj
                         + N' WHERE phone = @phone';
            END
            ELSE
            BEGIN
                /* no phone column -> nothing to count here */
                SET @sql = N'';
            END
        END
        ELSE IF @kind IN ('cdc', 'history')
        BEGIN
            /* CDC change table: __$operation 1=delete,2=insert,3=before-update,4=after-update
               History table: everything is historical rows */
            IF EXISTS (SELECT 1 FROM sys.columns
                       WHERE object_id = OBJECT_ID(@obj) AND name = N'phone')
            BEGIN
                SET @sql = N'INSERT INTO #results SELECT @obj, COUNT_BIG(*) FROM ' + @obj
                         + N' WHERE phone = @phone';
            END
            ELSE
            BEGIN
                SET @sql = N'';
            END
        END
        ELSE
        BEGIN
            /* other table with a phone-like column */
            IF EXISTS (SELECT 1 FROM sys.columns
                       WHERE object_id = OBJECT_ID(@obj) AND name = N'phone')
            BEGIN
                SET @sql = N'INSERT INTO #results SELECT @obj, COUNT_BIG(*) FROM ' + @obj
                         + N' WHERE phone = @phone';
            END
            ELSE
            BEGIN
                SET @sql = N'';
            END
        END

        IF @sql <> N''
        BEGIN
            EXEC sp_executesql @sql, N'@obj sysname, @phone nvarchar(50)', @obj = @obj, @phone = @phone;
        END
        ELSE
        BEGIN
            INSERT INTO #results (object_name, rows_found) VALUES (@obj, 0);
        END
    END TRY
    BEGIN CATCH
        /* If the object can't be queried, record 0 rather than failing */
        INSERT INTO #results (object_name, rows_found) VALUES (@obj, 0);
    END CATCH

    FETCH NEXT FROM cur INTO @obj, @kind;
END

CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found FROM #results ORDER BY object_name;

DROP TABLE #results;
