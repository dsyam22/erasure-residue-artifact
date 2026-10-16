SET NOCOUNT ON;

DECLARE @sql nvarchar(max);

SELECT @sql = STRING_AGG(
    CONCAT(
        N'SELECT ',
        QUOTENAME(s.name + N'.' + t.name, ''''),
        N' AS object_name, COUNT(*) AS rows_found FROM ',
        QUOTENAME(s.name),
        N'.',
        QUOTENAME(t.name),
        N' WHERE ',
        c.condition_sql
    ),
    N' UNION ALL '
)
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
CROSS APPLY (
    SELECT STRING_AGG(
        CONCAT(
            N'TRY_CONVERT(nvarchar(max), ',
            QUOTENAME(col.name),
            N') IN (N''42'', N''Subject_0000042'', N''subject42@example.invalid'', N''+1-555-0000042'')'
        ),
        N' OR '
    ) AS condition_sql
    FROM sys.columns AS col
    WHERE col.object_id = t.object_id
) AS c
WHERE t.is_ms_shipped = 0
  AND t.type = N'U';

IF @sql IS NOT NULL
BEGIN
    SET @sql = N'SELECT object_name, rows_found FROM (' + @sql + N') AS r ORDER BY object_name;';
    EXEC sys.sp_executesql @sql;
END;
