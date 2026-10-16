SET NOCOUNT ON;

DECLARE @u nvarchar(max);
DECLARE @sql nvarchar(max);

-- One SELECT per user table: counts rows where any character column contains
-- the erased name, email, or phone. Tables with no character columns get 0.
SELECT @u = STRING_AGG(CAST(
        N'SELECT CAST(' + QUOTENAME(s.name + N'.' + t.name, '''') + N' AS nvarchar(256)) AS object_name, '
      + N'CAST(COUNT(*) AS int) AS rows_found FROM '
      + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
      + N' WHERE ' + ISNULL(cond.c, N'1 = 0')
    AS nvarchar(max)), N' UNION ALL ')
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
OUTER APPLY (
    SELECT STRING_AGG(CAST(
            N'(CHARINDEX(@v_name, ' + QUOTENAME(c.name) + N') > 0 OR '
          + N'CHARINDEX(@v_email, ' + QUOTENAME(c.name) + N') > 0 OR '
          + N'CHARINDEX(@v_phone, ' + QUOTENAME(c.name) + N') > 0)'
        AS nvarchar(max)), N' OR ') AS c
    FROM sys.columns c
    JOIN sys.types ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = t.object_id
      AND ty.name IN ('char', 'varchar', 'nchar', 'nvarchar')
) cond
WHERE t.is_ms_shipped = 0;

SET @sql = N'SELECT object_name, rows_found FROM (' + @u + N') AS r ORDER BY object_name;';

EXEC sp_executesql
    @sql,
    N'@v_name nvarchar(200), @v_email nvarchar(200), @v_phone nvarchar(200)',
    @v_name  = N'Subject_0000042',
    @v_email = N'subject42@example.invalid',
    @v_phone = N'+1-555-0000042';
