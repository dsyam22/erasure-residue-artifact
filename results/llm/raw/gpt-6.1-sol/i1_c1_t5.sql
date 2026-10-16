/*
    Checks live rows in all accessible, non-system tables in llm_i1,
    including accessible temporal-history and CDC tables.

    This is a logical-row check, not proof of physical erasure. SELECT
    queries cannot comprehensively inspect deleted/ghost records,
    deallocated pages, transaction-log remnants, or backup contents.

    Only SELECT queries are executed against database objects.
    EXECUTE below runs the generated read-only SELECT batch.
*/
DECLARE @sql nvarchar(max);

SELECT @sql =
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'SELECT N''' +
            REPLACE(QUOTENAME(s.name) + N'.' + QUOTENAME(t.name), N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' AS src WHERE ' + COALESCE(p.predicate_sql, N'1 = 0')
        ),
        N' UNION ALL '
    ) WITHIN GROUP (ORDER BY s.name, t.name)
FROM [llm_i1].sys.tables AS t
JOIN [llm_i1].sys.schemas AS s
    ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CONVERT(nvarchar(max),
            CASE
                WHEN c.system_type_id IN
                     (35, 99, 167, 175, 231, 239, 241, 98)
                THEN
                    N'(CHARINDEX(N''Subject_0000042'', ' +
                    N'TRY_CONVERT(nvarchar(max), src.' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''subject42@example.invalid'', ' +
                    N'TRY_CONVERT(nvarchar(max), src.' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''+1-555-0000042'', ' +
                    N'TRY_CONVERT(nvarchar(max), src.' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0' +
                    CASE WHEN c.name = N'customer_id'
                         THEN N' OR TRY_CONVERT(bigint, TRY_CONVERT(nvarchar(max), src.' +
                              QUOTENAME(c.name) + N')) = 42'
                         ELSE N''
                    END + N')'
                WHEN c.name = N'customer_id'
                     AND c.system_type_id IN
                         (48, 52, 56, 127, 59, 62, 60, 106, 108, 122)
                THEN N'(src.' + QUOTENAME(c.name) + N' = 42)'
                ELSE NULL
            END
        ),
        N' OR '
    ) AS predicate_sql
    FROM [llm_i1].sys.columns AS c
    WHERE c.object_id = t.object_id
) AS p
WHERE t.is_ms_shipped = 0;

SELECT @sql =
    N'USE [llm_i1]; ' +
    COALESCE(
        N'SELECT object_name, rows_found FROM (' + @sql +
        N') AS results ORDER BY object_name;',
        N'SELECT CONVERT(nvarchar(517), NULL) AS object_name, ' +
        N'CONVERT(bigint, NULL) AS rows_found WHERE 1 = 0;'
    );

EXECUTE sys.sp_executesql @sql;
