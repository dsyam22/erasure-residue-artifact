DECLARE @sql nvarchar(max);

-- Scan base tables directly, including temporal history tables.
-- Count a row once if any in-scope value remains in that row.
SELECT @sql =
    STRING_AGG(
        CAST(
            N'SELECT N''' +
            REPLACE(s.name + N'.' + t.name, N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found
              FROM [llm_i9].' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' WHERE ' + COALESCE(p.predicate, N'1 = 0')
            AS nvarchar(max)
        ),
        N' UNION ALL '
    )
FROM [llm_i9].sys.tables AS t
JOIN [llm_i9].sys.schemas AS s
  ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CAST(
            CASE
                WHEN c.name = N'customer_id'
                 AND c.system_type_id IN
                     (48, 52, 56, 127, 106, 108, 59, 62, 60, 122,
                      167, 175, 231, 239, 35, 99, 98)
                THEN
                    N'TRY_CONVERT(decimal(38,10), CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) + N')) = 42'
                ELSE N'1 = 0'
            END
            +
            CASE
                WHEN c.system_type_id IN
                     (167, 175, 231, 239, 35, 99, 241, 98)
                THEN
                    N' OR (
                        CHARINDEX(
                            N''Subject_0000042'',
                            CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                            N') COLLATE Latin1_General_100_BIN2
                        ) > 0
                        OR CHARINDEX(
                            N''subject42@example.invalid'',
                            CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                            N') COLLATE Latin1_General_100_BIN2
                        ) > 0
                        OR CHARINDEX(
                            N''+1-555-0000042'',
                            CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                            N') COLLATE Latin1_General_100_BIN2
                        ) > 0
                    )'
                ELSE N''
            END
            AS nvarchar(max)
        ),
        N' OR '
    ) AS predicate
    FROM [llm_i9].sys.columns AS c
    WHERE c.object_id = t.object_id
) AS p
WHERE t.is_ms_shipped = 0;

SELECT @sql =
    CASE
        WHEN @sql IS NULL THEN
            N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                     CAST(NULL AS bigint) AS rows_found
              WHERE 1 = 0;'
        ELSE
            N'SELECT object_name, rows_found
              FROM (' + @sql + N') AS findings
              ORDER BY object_name;'
    END;

EXEC sys.sp_executesql @sql;
