DECLARE @sql nvarchar(max);

-- Scan every user table, including temporal history tables.
-- Match original text wherever it occurs in character/XML columns,
-- and match customer_id in columns bearing that name.
SELECT @sql =
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'SELECT N''' +
            REPLACE(s.name + N'.' + t.name, N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            QUOTENAME(N'llm_i2') + N'.' +
            QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' WHERE ' + COALESCE(p.predicate_sql, N'1 = 0')
        ),
        N' UNION ALL '
    ) WITHIN GROUP (ORDER BY s.name, t.name)
FROM [llm_i2].sys.tables AS t
JOIN [llm_i2].sys.schemas AS s
    ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CONVERT(nvarchar(max),
            CASE
                WHEN c.system_type_id IN
                     (35, 99, 167, 175, 231, 239, 241)
                THEN
                    N'(CHARINDEX(N''Subject_0000042'', ' +
                    N'TRY_CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''subject42@example.invalid'', ' +
                    N'TRY_CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''+1-555-0000042'', ' +
                    N'TRY_CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0' +
                    CASE WHEN c.name = N'customer_id'
                         THEN N' OR TRY_CONVERT(decimal(38,10), ' +
                              N'TRY_CONVERT(nvarchar(max), ' +
                              QUOTENAME(c.name) + N')) = 42'
                         ELSE N''
                    END + N')'
                WHEN c.name = N'customer_id'
                     AND c.system_type_id IN
                         (48, 52, 56, 59, 60, 62, 106, 108, 122, 127)
                THEN
                    N'(' + QUOTENAME(c.name) + N' = 42)'
            END
        ),
        N' OR '
    ) AS predicate_sql
    FROM [llm_i2].sys.columns AS c
    WHERE c.object_id = t.object_id
) AS p
WHERE t.is_ms_shipped = 0;

SELECT @sql =
    CASE WHEN @sql IS NULL
         THEN N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                       CAST(NULL AS bigint) AS rows_found
                WHERE 1 = 0;'
         ELSE @sql + N' ORDER BY object_name;'
    END;

EXEC [llm_i2].sys.sp_executesql @sql;
