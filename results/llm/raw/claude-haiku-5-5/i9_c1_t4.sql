SET NOCOUNT ON;

DECLARE @cond nvarchar(max) =
    N'(CHARINDEX(N''Subject_0000042'', {c}) > 0 OR '
  + N'CHARINDEX(N''subject42@example.invalid'', {c}) > 0 OR '
  + N'CHARINDEX(N''+1-555-0000042'', {c}) > 0)';

DECLARE @sql nvarchar(max);

SELECT @sql = STRING_AGG(
        CAST(
            N'SELECT ' + QUOTENAME(x.obj, '''') + N' AS object_name, '
          + N'(SELECT COUNT(*) FROM ' + x.qobj + N' WHERE ' + x.pred + N') AS rows_found'
        AS nvarchar(max)),
        N' UNION ALL ')
FROM (
    SELECT
        s.name + N'.' + t.name                       AS obj,
        QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) AS qobj,
        COALESCE(
            (SELECT STRING_AGG(CAST(REPLACE(@cond, N'{c}', QUOTENAME(c.name)) AS nvarchar(max)), N' OR ')
             FROM sys.columns AS c
             WHERE c.object_id = t.object_id
               AND c.system_type_id IN (167, 175, 231, 239)),  -- varchar, char, nvarchar, nchar
            N'0=1') AS pred
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
) AS x;

IF @sql IS NULL
    SET @sql = N'SELECT CAST(NULL AS nvarchar(256)) AS object_name, CAST(NULL AS int) AS rows_found WHERE 1 = 0;';

EXEC sys.sp_executesql @sql;
