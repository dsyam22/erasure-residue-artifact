/*
  Checks live, SQL-readable user tables, including temporal history tables.
  Requires SELECT permission on every table and complete metadata visibility.
  This does not inspect transaction logs, deallocated pages, or backup files.
*/
DECLARE @sql nvarchar(max);

SELECT @sql =
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'SELECT N''' +
            REPLACE(QUOTENAME(s.name) + N'.' + QUOTENAME(t.name), N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            N'[llm_i5].' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' WHERE ' + COALESCE(p.predicate, N'1 = 0')
        ),
        N' UNION ALL '
    ) WITHIN GROUP (ORDER BY s.name, t.name)
FROM [llm_i5].sys.tables AS t
JOIN [llm_i5].sys.schemas AS s
    ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CONVERT(nvarchar(max),
            CASE
                WHEN c.system_type_id IN
                     (35, 99, 167, 175, 231, 239, 241)
                THEN
                    N'(' +
                    N'CHARINDEX(N''Subject_0000042'', CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''subject42@example.invalid'', CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''+1-555-0000042'', CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0' +
                    CASE
                        WHEN c.name = N'customer_id'
                        THEN N' OR TRY_CONVERT(bigint, CONVERT(nvarchar(max), ' +
                             QUOTENAME(c.name) + N')) = 42'
                        ELSE N''
                    END +
                    N')'
                WHEN c.name = N'customer_id'
                     AND c.system_type_id IN
                         (48, 52, 56, 59, 60, 62, 106, 108, 122, 127)
                THEN QUOTENAME(c.name) + N' = 42'
            END
        ),
        N' OR '
    ) WITHIN GROUP (ORDER BY c.column_id) AS predicate
    FROM [llm_i5].sys.columns AS c
    WHERE c.object_id = t.object_id
) AS p
WHERE t.is_ms_shipped = 0;

SELECT @sql =
    CASE
        WHEN @sql IS NULL
        THEN N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                       CAST(NULL AS bigint) AS rows_found
                WHERE 1 = 0;'
        ELSE N'SELECT object_name, rows_found FROM (' +
             @sql + N') AS findings ORDER BY object_name;'
    END;

EXEC sys.sp_executesql @sql;
