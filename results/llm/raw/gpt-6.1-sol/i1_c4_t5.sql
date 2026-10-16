USE [llm_i1];

-- Checks current, SQL-readable table contents, including CDC tables even when
-- marked is_ms_shipped. Matches customer_id = 42 and occurrences of the original
-- name, email, or phone in character, XML, sql_variant, and binary columns.
-- A zero count does not prove physical erasure from transaction logs, freed
-- pages, backups, encrypted/encoded payloads, or objects hidden by permissions.

DECLARE @sql nvarchar(max);

;WITH ColumnExpressions AS
(
    SELECT
        c.object_id,
        c.column_id,
        CASE
            WHEN c.system_type_id IN (35, 99, 167, 175, 231, 239, 241, 98)
            THEN
                N'TRY_CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N')'
            WHEN c.system_type_id IN (34, 165, 173)
            THEN
                N'TRY_CONVERT(nvarchar(max), CONVERT(varbinary(max), '
                + QUOTENAME(c.name) + N'))'
        END AS text_expression,
        CASE
            WHEN c.system_type_id IN (34, 165, 173)
            THEN
                N'TRY_CONVERT(varchar(max), CONVERT(varbinary(max), '
                + QUOTENAME(c.name) + N'))'
        END AS binary_ascii_expression,
        CASE
            WHEN c.name = N'customer_id'
             AND c.system_type_id IN
                 (48, 52, 56, 127, 106, 108, 60, 122, 59, 62,
                  35, 99, 167, 175, 231, 239, 98)
            THEN
                N'TRY_CONVERT(nvarchar(max), ' + QUOTENAME(c.name)
                + N') = N''42'''
        END AS id_predicate
    FROM sys.columns AS c
    INNER JOIN sys.tables AS t ON t.object_id = c.object_id
),
ColumnPredicates AS
(
    SELECT
        object_id,
        column_id,
        CONVERT(nvarchar(max),
            CASE WHEN text_expression IS NOT NULL THEN
                N'CHARINDEX(N''Subject_0000042'', ' + text_expression + N') > 0'
                + N' OR CHARINDEX(N''subject42@example.invalid'', '
                + text_expression + N') > 0'
                + N' OR CHARINDEX(N''+1-555-0000042'', '
                + text_expression + N') > 0'
            ELSE N'1 = 0' END
            + CASE WHEN binary_ascii_expression IS NOT NULL THEN
                N' OR CHARINDEX(''Subject_0000042'', '
                + binary_ascii_expression + N') > 0'
                + N' OR CHARINDEX(''subject42@example.invalid'', '
                + binary_ascii_expression + N') > 0'
                + N' OR CHARINDEX(''+1-555-0000042'', '
                + binary_ascii_expression + N') > 0'
            ELSE N'' END
            + CASE WHEN id_predicate IS NOT NULL
                   THEN N' OR ' + id_predicate ELSE N'' END
        ) AS predicate
    FROM ColumnExpressions
    WHERE text_expression IS NOT NULL
       OR binary_ascii_expression IS NOT NULL
       OR id_predicate IS NOT NULL
),
TablePredicates AS
(
    SELECT
        object_id,
        STRING_AGG(predicate, N' OR ')
            WITHIN GROUP (ORDER BY column_id) AS predicate
    FROM ColumnPredicates
    GROUP BY object_id
)
SELECT @sql =
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'SELECT N'''
            + REPLACE(s.name + N'.' + t.name, N'''', N'''''')
            + N''' AS object_name, COUNT_BIG(*) AS rows_found FROM '
            + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
            + N' WHERE (' + COALESCE(p.predicate, N'1 = 0') + N')'
        ),
        N' UNION ALL '
    ) WITHIN GROUP (ORDER BY s.name, t.name)
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN TablePredicates AS p ON p.object_id = t.object_id;

SELECT @sql =
    CASE WHEN @sql IS NULL THEN
        N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                 CAST(NULL AS bigint) AS rows_found WHERE 1 = 0;'
    ELSE
        N'SELECT object_name, rows_found FROM ('
        + @sql + N') AS results ORDER BY object_name;'
    END;

EXEC sys.sp_executesql @sql;
