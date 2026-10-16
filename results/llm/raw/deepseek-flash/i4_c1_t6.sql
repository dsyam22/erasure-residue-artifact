/* Read-only verification script: checks whether the subject's original
   personal data still exists anywhere in the database.
   Returns exactly one result set: object_name, rows_found. */

SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @member_id   int = 42;

DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email     nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone     nvarchar(200) = N'+1-555-0000042';

/* Collect candidate tables/columns dynamically from the catalog, so that
   any table holding these values is checked, not just the two known ones. */
CREATE TABLE #candidates (
    object_name sysname,
    schema_name sysname,
    table_name  sysname,
    column_name sysname,
    data_type   sysname
);

INSERT INTO #candidates (object_name, schema_name, table_name, column_name, data_type)
SELECT
    QUOTENAME(s.name) + N'.' + QUOTENAME(t.name),
    s.name,
    t.name,
    c.name,
    ty.name
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types   AS ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND c.is_computed = 0
  AND ty.name IN (N'nvarchar', N'varchar', N'nchar', N'char', N'ntext', N'text');

/* Build a UNION ALL query: one SELECT per (table, column) that counts rows
   matching any of the subject's original identifiers. */
DECLARE @sql nvarchar(max) = N'';
DECLARE @obj sysname, @sch sysname, @tbl sysname, @col sysname, @dtype sysname;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT object_name, schema_name, table_name, column_name, data_type
    FROM #candidates;

OPEN cur;
FETCH NEXT FROM cur INTO @obj, @sch, @tbl, @col, @dtype;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @sql <> N'' SET @sql += N' UNION ALL ';

    SET @sql +=
        N'SELECT N''' + REPLACE(@obj, N'''', N'''''') + N''' AS object_name, '
      + N'COUNT_BIG(*) AS rows_found FROM '
      + QUOTENAME(@sch) + N'.' + QUOTENAME(@tbl)
      + N' WHERE '
      + N'CAST(' + QUOTENAME(@col) + N' AS nvarchar(max)) IN ('
      + N'@p_name, @p_email, @p_phone)';

    FETCH NEXT FROM cur INTO @obj, @sch, @tbl, @col, @dtype;
END

CLOSE cur;
DEALLOCATE cur;

/* Also explicitly account for the known in-scope tables even if the
   catalog scan produced no matching columns (defensive). */
IF @sql = N''
BEGIN
    SET @sql =
        N'SELECT N''dbo.customer'' AS object_name, COUNT_BIG(*) AS rows_found '
      + N'FROM dbo.customer WHERE CAST(full_name AS nvarchar(max)) IN (@p_name,@p_email,@p_phone) '
      + N'   OR CAST(email AS nvarchar(max)) IN (@p_name,@p_email,@p_phone) '
      + N'   OR CAST(phone AS nvarchar(max)) IN (@p_name,@p_email,@p_phone) '
      + N'UNION ALL '
      + N'SELECT N''dbo.member'', COUNT_BIG(*) FROM dbo.member '
      + N'WHERE CAST(full_name AS nvarchar(max)) IN (@p_name,@p_email,@p_phone) '
      + N'   OR CAST(email AS nvarchar(max)) IN (@p_name,@p_email,@p_phone) '
      + N'   OR CAST(phone AS nvarchar(max)) IN (@p_name,@p_email,@p_phone)';
END

/* Collapse per-column counts into one row per table, then order. */
DECLARE @final nvarchar(max) =
    N'WITH hits AS (' + @sql + N') '
  + N'SELECT object_name, SUM(rows_found) AS rows_found '
  + N'FROM hits GROUP BY object_name ORDER BY object_name;';

EXEC sp_executesql
    @final,
    N'@p_name nvarchar(200), @p_email nvarchar(200), @p_phone nvarchar(200)',
    @p_name = @full_name,
    @p_email = @email,
    @p_phone = @phone;

DROP TABLE #candidates;
