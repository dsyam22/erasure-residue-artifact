SET NOCOUNT ON;

DECLARE @sql nvarchar(max);

SELECT @sql = STRING_AGG(CAST(
    N'SELECT ' + QUOTENAME(s.name + N'.' + t.name, N'''') + N' AS object_name, '
  + N'COUNT(*) AS rows_found FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
  + N' WHERE ' +
  ISNULL((
      SELECT STRING_AGG(CAST(
          N'CHARINDEX(N''Subject_0000042'', ' + QUOTENAME(c.name) + N') > 0 OR '
        + N'CHARINDEX(N''subject42@example.invalid'', ' + QUOTENAME(c.name) + N') > 0 OR '
        + N'CHARINDEX(N''+1-555-0000042'', ' + QUOTENAME(c.name) + N') > 0'
        AS nvarchar(max)), N' OR ')
      FROM sys.columns AS c
      JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
      WHERE c.object_id = t.object_id
        AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar')
    ), N'1=0')
  AS nvarchar(max)), N' UNION ALL ')
  WITHIN GROUP (ORDER BY s.name, t.name)
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0;

IF @sql IS NULL
    SET @sql = N'SELECT CAST(N''none'' AS sysnamel) AS object_name, CAST(0 AS int) AS rows_found WHERE 1 = 0;';

EXEC sys.sp_executesql @sql;
