SET NOCOUNT ON;

-- Subject's original personal data (exact match, all character-type columns in every user table)
CREATE TABLE #scan
(
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @sql nvarchar(max) = N'';

SELECT @sql += N'INSERT INTO #scan (object_name, rows_found) SELECT '
    + QUOTENAME(s.name + N'.' + t.name, '''')
    + N', COUNT(*) FROM (SELECT 1 AS x FROM '
    + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N' AS p WHERE '
    + COALESCE((
        SELECT STRING_AGG(CAST(
                 N'p.' + QUOTENAME(c.name)
               + N' IN (N''Subject_0000042'', N''subject42@example.invalid'', N''+1-555-0000042'')'
               AS nvarchar(max)), N' OR ')
        FROM sys.columns AS c
        JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
        WHERE c.object_id = t.object_id
          AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar')
      ), N'1 = 0')
    + N') AS q;' + NCHAR(10)
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id;

IF @sql <> N''
    EXEC sys.sp_executesql @sql;

SELECT object_name, rows_found
FROM #scan
ORDER BY object_name;

DROP TABLE #scan;
