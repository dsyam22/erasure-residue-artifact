DECLARE @sql nvarchar(max);

-- Scan current tables, temporal history tables, and other persisted user
-- tables independently. Retained numeric identifiers alone are not treated
-- as residual original names, email addresses, or phone numbers.
SELECT @sql =
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'SELECT N''' +
            REPLACE(s.name + N'.' + t.name, N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            QUOTENAME(N'llm_i4') + N'.' +
            QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            CASE
                WHEN p.predicate IS NULL THEN N' WHERE 1 = 0'
                ELSE N' WHERE ' + p.predicate
            END
        ),
        N' UNION ALL '
    )
FROM [llm_i4].sys.tables AS t
JOIN [llm_i4].sys.schemas AS s
    ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CONVERT(nvarchar(max),
            N'(' +
            N'CHARINDEX(N''Subject_0000042'', ' + v.expression +
                N' COLLATE Latin1_General_100_BIN2) > 0 OR ' +
            N'CHARINDEX(N''subject42@example.invalid'', ' + v.expression +
                N' COLLATE Latin1_General_100_BIN2) > 0 OR ' +
            N'CHARINDEX(N''+1-555-0000042'', ' + v.expression +
                N' COLLATE Latin1_General_100_BIN2) > 0' +
            CASE
                WHEN c.system_type_id IN (34, 165, 173) THEN
                    N' OR CHARINDEX(''Subject_0000042'', ' +
                        N'TRY_CONVERT(varchar(max), ' + QUOTENAME(c.name) +
                        N') COLLATE Latin1_General_100_BIN2) > 0' +
                    N' OR CHARINDEX(''subject42@example.invalid'', ' +
                        N'TRY_CONVERT(varchar(max), ' + QUOTENAME(c.name) +
                        N') COLLATE Latin1_General_100_BIN2) > 0' +
                    N' OR CHARINDEX(''+1-555-0000042'', ' +
                        N'TRY_CONVERT(varchar(max), ' + QUOTENAME(c.name) +
                        N') COLLATE Latin1_General_100_BIN2) > 0'
                ELSE N''
            END +
            N')'
        ),
        N' OR '
    ) AS predicate
    FROM [llm_i4].sys.columns AS c
    CROSS APPLY
    (
        SELECT N'TRY_CONVERT(nvarchar(max), ' +
               QUOTENAME(c.name) + N')' AS expression
    ) AS v
    WHERE c.object_id = t.object_id
      AND c.system_type_id IN
          (34, 35, 98, 99, 165, 167, 173, 175, 231, 239, 241)
) AS p
WHERE t.is_ms_shipped = 0;

SELECT @sql =
    CASE
        WHEN @sql IS NULL THEN
            N'SELECT CAST(NULL AS nvarchar(517)) AS object_name, ' +
            N'CAST(NULL AS bigint) AS rows_found WHERE 1 = 0;'
        ELSE
            N'SELECT object_name, rows_found FROM (' + @sql +
            N') AS findings ORDER BY object_name;'
    END;

-- Executes only the generated SELECT; no database data is modified.
EXEC sys.sp_executesql @sql;
