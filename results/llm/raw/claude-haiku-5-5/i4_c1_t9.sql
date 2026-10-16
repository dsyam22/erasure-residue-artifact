SET NOCOUNT ON;

CREATE TABLE #subject_values (val nvarchar(200) NOT NULL);
INSERT INTO #subject_values (val)
VALUES (N'Subject_0000042'),
       (N'subject42@example.invalid'),
       (N'+1-555-0000042');

DECLARE @sql nvarchar(max);

SELECT @sql =
    N'SELECT object_name, rows_found FROM ('
    + STRING_AGG(
        CAST(
            N'SELECT CAST(N''' + REPLACE(s.name + N'.' + t.name, N'''', N'''''') + N''' AS nvarchar(256)) AS object_name, '
          + N'CAST((SELECT COUNT(*) FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
          + N' WHERE ' + ISNULL(p.pred, N'1=0') + N') AS int) AS rows_found'
        AS nvarchar(max)),
        N' UNION ALL ')
    + N') AS x ORDER BY object_name;'
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
OUTER APPLY (
    SELECT STRING_AGG(
        CAST(N'CHARINDEX(N''' + REPLACE(v.val, N'''', N'''''') + N''', '
           + QUOTENAME(c.name) + N' COLLATE DATABASE_DEFAULT) > 0'
        AS nvarchar(max)),
        N' OR ') AS pred
    FROM sys.columns AS c
    CROSS JOIN #subject_values AS v
    WHERE c.object_id = t.object_id
      AND c.user_type_id IN (167, 231, 175, 239)  -- varchar, nvarchar, char, nchar
) AS p;

IF @sql IS NOT NULL
    EXEC sys.sp_executesql @sql;

DROP TABLE #subject_values;
