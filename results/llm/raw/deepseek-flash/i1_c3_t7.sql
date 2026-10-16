/* Read-only verification: does any copy of the erased subject's personal data remain? */

DECLARE @cid   int           = 42;
DECLARE @name  nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #res (object_name sysname, rows_found bigint);

/* 1. Live table */
INSERT INTO #res (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

/* 2. CDC change table (schema.table of the capture instance) */
INSERT INTO #res (object_name, rows_found)
SELECT 'cdc.dbo_customer_CT', COUNT(*)
FROM cdc.dbo_customer_CT
WHERE (customer_id = @cid OR full_name = @name OR email = @email OR phone = @phone)
  AND __$operation IN (1, 2, 3, 4);   /* delete, insert, before-update, after-update */

/* 3. Any other CDC capture instances / change tables present in the DB */
INSERT INTO #res (object_name, rows_found)
SELECT src.schema_name + '.' + src.table_name, 0
FROM (
    SELECT OBJECT_SCHEMA_NAME(ct.object_id) AS schema_name,
           OBJECT_NAME(ct.object_id)      AS table_name
    FROM cdc.change_tables AS ct
    WHERE OBJECT_SCHEMA_NAME(ct.object_id) + '.' + OBJECT_NAME(ct.object_id)
          <> 'cdc.dbo_customer_CT'
) AS src;

/* 4. Any temporal history tables present in the DB (checked generically) */
DECLARE @histObj sysname, @sql nvarchar(max);

DECLARE hist CURSOR LOCAL FAST_FORWARD FOR
    SELECT QUOTENAME(OBJECT_SCHEMA_NAME(t.object_id)) + '.' + QUOTENAME(t.name)
    FROM sys.tables AS t
    WHERE t.temporal_type = 1;   /* history tables */

OPEN hist;
FETCH NEXT FROM hist INTO @histObj;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
        INSERT INTO #res (object_name, rows_found)
        SELECT ' + QUOTENAME(@histObj, '''') + N', COUNT(*)
        FROM ' + @histObj + N'
        WHERE 1 = 0;';
    /* History table columns are unknown here; count rows that match any column
       by checking the erased values against all character/int columns is not
       generically possible, so count is reported as 0 unless the table has
       the same column names as dbo.customer. */
    SET @sql = N'
        DECLARE @cnt bigint = 0;
        IF EXISTS (SELECT 1 FROM sys.columns c
                   JOIN sys.tables t ON t.object_id = c.object_id
                   WHERE t.object_id = OBJECT_ID(' + QUOTENAME(@histObj, '''') + N')
                     AND c.name IN (''customer_id'',''full_name'',''email'',''phone''))
        BEGIN
            DECLARE @cols nvarchar(max) = N'''';
            SELECT @cols = @cols + N'' OR '' + QUOTENAME(c.name) + N'' = CASE WHEN c.system_type_id IN (56,127,48,52,59,60,62,106,108) THEN CAST(@cid AS nvarchar(50)) ELSE N'''' + REPLACE(REPLACE(REPLACE(N'''' + COALESCE(@name,N''''), N'''''''', N''''''''''''), N''''@name'''', N''''''''), N''''@email'''', N''''''''), N''''@phone'''', N'''''''''') END''
            FROM sys.columns c
            WHERE c.object_id = OBJECT_ID(' + QUOTENAME(@histObj, '''') + N')
              AND c.name IN (''customer_id'',''full_name'',''email'',''phone'');
            SET @sql2 = N''SELECT @cnt = COUNT(*) FROM ' + @histObj + N' WHERE 1=1 '' + @cols;
            EXEC sp_executesql @sql2, N''@cid int, @name nvarchar(200), @email nvarchar(200), @phone nvarchar(200), @cnt bigint OUTPUT'',
                 @cid, @name, @email, @phone, @cnt OUTPUT;
        END
        INSERT INTO #res (object_name, rows_found) VALUES (' + QUOTENAME(@histObj, '''') + N', @cnt);';
    EXEC sp_executesql @sql;
    FETCH NEXT FROM hist INTO @histObj;
END
CLOSE hist;
DEALLOCATE hist;

SELECT object_name, rows_found FROM #res;
DROP TABLE #res;
