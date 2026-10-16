USE [llm_i3];

DECLARE @sql nvarchar(max);

-- Scan every user table, including temporal history tables.
-- Search textual payloads for the original values and identifier columns for 42.
SELECT @sql =
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'SELECT N''' +
            REPLACE(s.name + N'.' + t.name, N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' WHERE ' + COALESCE(p.predicate, N'1 = 0')
        ),
        N' UNION ALL '
    )
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CONVERT(nvarchar(max),
            CASE
                WHEN c.system_type_id IN (35, 99, 167, 175, 231, 239, 241)
                THEN
                    N'(CHARINDEX(N''Subject_0000042'', ' +
                    N'CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''subject42@example.invalid'', ' +
                    N'CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''+1-555-0000042'', ' +
                    N'CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0' +
                    CASE
                        WHEN c.name IN (N'customer_id', N'member_id')
                        THEN
                            N' OR TRY_CONVERT(decimal(38, 10), ' +
                            N'CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                            N')) = 42'
                        ELSE N''
                    END +
                    N')'
                WHEN c.name IN (N'customer_id', N'member_id')
                     AND c.system_type_id IN
                         (48, 52, 56, 59, 60, 62, 106, 108, 122, 127)
                THEN QUOTENAME(c.name) + N' = 42'
            END
        ),
        N' OR '
    ) AS predicate
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
) AS p
WHERE t.is_ms_shipped = 0;

SELECT @sql =
    CASE
        WHEN @sql IS NULL
        THEN
            N'SELECT CAST(NULL AS nvarchar(517)) AS object_name, ' +
            N'CAST(NULL AS bigint) AS rows_found WHERE 1 = 0;'
        ELSE
            N'SELECT object_name, rows_found FROM (' + @sql +
            N') AS findings ORDER BY object_name;'
    END;

EXEC sys.sp_executesql @sql;
