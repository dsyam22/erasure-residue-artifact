USE [llm_i5];

DECLARE @sql nvarchar(max);

-- Scan every user table, including temporal history tables.
-- Count each matching row once, even if multiple columns match.
SELECT @sql =
    STRING_AGG(
        CAST(
            N'SELECT N''' +
            REPLACE(s.name + N'.' + t.name, N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' WHERE ' + COALESCE(p.predicate_sql, N'1 = 0')
            AS nvarchar(max)
        ),
        N' UNION ALL '
    )
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CAST(
            CASE
                WHEN c.system_type_id IN
                     (35, 99, 167, 175, 231, 239, 241, 98)
                THEN
                    N'(' +
                    N'CHARINDEX(N''Subject_0000042'', TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''subject42@example.invalid'', TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''+1-555-0000042'', TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0' +
                    CASE
                        WHEN c.name = N'customer_id'
                        THEN N' OR TRY_CONVERT(nvarchar(max), ' +
                             QUOTENAME(c.name) + N') = N''42'''
                        ELSE N''
                    END +
                    N')'
                WHEN c.name = N'customer_id'
                     AND c.system_type_id IN
                         (48, 52, 56, 127, 106, 108, 59, 62, 60, 122)
                THEN QUOTENAME(c.name) + N' = 42'
            END
            AS nvarchar(max)
        ),
        N' OR '
    ) AS predicate_sql
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
) AS p
WHERE t.is_ms_shipped = 0;

IF @sql IS NULL
    SET @sql =
        N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                 CAST(NULL AS bigint) AS rows_found
          WHERE 1 = 0;';
ELSE
    SET @sql =
        N'SELECT object_name, rows_found FROM (' +
        @sql +
        N') AS results ORDER BY object_name;';

EXEC sys.sp_executesql @sql;
