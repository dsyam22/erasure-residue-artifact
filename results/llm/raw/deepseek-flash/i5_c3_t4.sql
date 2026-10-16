/* Read-only verification: does the erased subject's personal data still exist anywhere? */

DECLARE @cid    int           = 42;
DECLARE @name   nvarchar(200) = N'Subject_0000042';
DECLARE @email  nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone  nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

/* 1. dbo.customer — live table (row may or may not still be present) */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @name
   OR email     = @email
   OR phone     = @phone;

/* 2. dbo.customer_history — system-versioned temporal history table */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer_history',
       COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @cid
   OR full_name = @name
   OR email     = @email
   OR phone     = @phone;

/* 3. dbo.customer — temporal ALL view (current + history, in case of renamed history table) */
IF OBJECT_ID(N'dbo.customer', N'U') IS NOT NULL
   AND EXISTS (SELECT 1
               FROM sys.tables
               WHERE object_id = OBJECT_ID(N'dbo.customer')
                 AND temporal_type = 2)
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer (FOR SYSTEM_TIME ALL)',
           COUNT(*)
    FROM dbo.customer FOR SYSTEM_TIME ALL
    WHERE customer_id = @cid
       OR full_name = @name
       OR email     = @email
       OR phone     = @phone;
END

/* 4. Change tracking / CDC — not enabled per configuration, but verify */
IF EXISTS (SELECT 1 FROM sys.change_tracking_tables)
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'sys.change_tracking_tables (tracked tables)',
           COUNT(*)
    FROM sys.change_tracking_tables;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'sys.change_tracking_tables (change tracking)', 0;
END

IF EXISTS (SELECT 1
           FROM sys.databases
           WHERE name = DB_NAME()
             AND is_cdc_enabled = 1)
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.change_tables',
           COUNT(*)
    FROM cdc.change_tables;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.change_tables (CDC)', 0;
END

/* 5. Any other user table in the database that stores the subject's
      original values in a character column — scan text columns of
      non-system tables other than the ones already checked. */
DECLARE @sql nvarchar(max) = N'';

SELECT @sql = @sql +
    N'INSERT INTO #results (object_name, rows_found)
      SELECT N''' + REPLACE(QUOTENAME(sch.name) + N'.' + QUOTENAME(tab.name), N'''', N'''''') + N''',
             COUNT(*)
      FROM ' + QUOTENAME(sch.name) + N'.' + QUOTENAME(tab.name) + N'
      WHERE ' +
      STUFF((
          SELECT N' OR ' + QUOTENAME(col.name) + N' LIKE N''%'' + @p + N''%'''
          FROM sys.columns col
          JOIN sys.types  ty ON ty.user_type_id = col.user_type_id
          WHERE col.object_id = tab.object_id
            AND ty.name IN (N'nvarchar', N'varchar', N'nchar', N'char', N'ntext', N'text')
          FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 4, N'') + N';'
FROM sys.tables  tab
JOIN sys.schemas sch ON sch.schema_id = tab.schema_id
WHERE tab.is_ms_shipped = 0
  AND tab.temporal_type <> 1                     /* skip history tables already checked */
  AND NOT (sch.name = N'dbo' AND tab.name = N'customer')
  AND EXISTS (SELECT 1
              FROM sys.columns col
              JOIN sys.types  ty ON ty.user_type_id = col.user_type_id
              WHERE col.object_id = tab.object_id
                AND ty.name IN (N'nvarchar', N'varchar', N'nchar', N'char', N'ntext', N'text'));

IF @sql <> N''
BEGIN
    DECLARE @p nvarchar(200) = @name;
    EXEC sp_executesql @sql, N'@p nvarchar(200)', @p = @p;

    SET @p = @email;
    EXEC sp_executesql @sql, N'@p nvarchar(200)', @p = @p;

    SET @p = @phone;
    EXEC sp_executesql @sql, N'@p nvarchar(200)', @p = @p;
END

/* Final single result set */
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
