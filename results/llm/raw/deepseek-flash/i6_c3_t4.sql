DECLARE @phone nvarchar(100) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

/* dbo.customer - phone column was dropped, check remaining columns for the phone value */
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.customer') AND name = 'phone')
    INSERT INTO #results
    SELECT 'dbo.customer', COUNT_BIG(*)
    FROM dbo.customer
    WHERE CONVERT(nvarchar(4000), phone) = @phone;
ELSE
    INSERT INTO #results VALUES ('dbo.customer', 0);

/* CDC change table cdc.dbo_customer_CT - scan all columns for the phone value */
IF OBJECT_ID('cdc.dbo_customer_CT') IS NOT NULL
BEGIN
    DECLARE @sql nvarchar(max) = N'';
    SELECT @sql = @sql + N'INSERT INTO #results SELECT ''cdc.dbo_customer_CT'', COUNT_BIG(*) FROM cdc.dbo_customer_CT WHERE CONVERT(nvarchar(4000), [' + c.name + N']) = @phone;'
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID('cdc.dbo_customer_CT')
      AND c.system_type_id IN (SELECT system_type_id FROM sys.types WHERE name IN ('nvarchar','nchar','varchar','char','text','ntext'));

    IF @sql = N''
        INSERT INTO #results VALUES ('cdc.dbo_customer_CT', 0);
    ELSE
        EXEC sp_executesql @sql, N'@phone nvarchar(100)', @phone = @phone;
END
ELSE
    INSERT INTO #results VALUES ('cdc.dbo_customer_CT', 0);

SELECT object_name, rows_found FROM #results;
