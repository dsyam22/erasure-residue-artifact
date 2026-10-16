USE [llm_i8];

-- Read-only scan of all catalog-visible tables, including temporal history
-- and CDC tables. Requires SELECT permission on every table being scanned.
--
-- This checks current logical rows, not physical remnants in deallocated pages,
-- transaction logs, backups, encrypted payloads, or external storage. A zero
-- count therefore does not prove that all physical copies have been erased.
-- EXEC below executes only the dynamically constructed SELECT statement.

DECLARE @sql nvarchar(max);

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
                -- Character data, XML, and sql_variant.
                WHEN c.system_type_id IN (35, 99, 167, 175, 231, 239, 241, 98)
                THEN
                    N'(' +
                    N'CHARINDEX(N''Subject_0000042'', TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''subject42@example.invalid'', TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''+1-555-0000042'', TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0' +
                    CASE WHEN c.name = N'customer_id'
                         THEN N' OR TRY_CONVERT(nvarchar(max), ' +
                              QUOTENAME(c.name) + N') = N''42'''
                         ELSE N''
                    END +
                    N')'

                -- Binary data: look for both ASCII/UTF-8 and UTF-16 encodings.
                WHEN c.system_type_id IN (34, 165, 173, 189)
                THEN
                    N'(' +
                    N'CHARINDEX(CONVERT(varbinary(max), ''Subject_0000042''), CONVERT(varbinary(max), ' +
                    QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), N''Subject_0000042''), CONVERT(varbinary(max), ' +
                    QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), ''subject42@example.invalid''), CONVERT(varbinary(max), ' +
                    QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), N''subject42@example.invalid''), CONVERT(varbinary(max), ' +
                    QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), ''+1-555-0000042''), CONVERT(varbinary(max), ' +
                    QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), N''+1-555-0000042''), CONVERT(varbinary(max), ' +
                    QUOTENAME(c.name) + N')) > 0)'

                -- Numeric customer identifiers.
                WHEN c.name = N'customer_id'
                     AND c.system_type_id IN
                         (48, 52, 56, 59, 60, 62, 106, 108, 122, 127)
                THEN QUOTENAME(c.name) + N' = 42'
            END
        ),
        N' OR '
    ) AS predicate
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
) AS p;

SELECT @sql =
    CASE
        WHEN @sql IS NULL THEN
            N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                     CAST(NULL AS bigint) AS rows_found
              WHERE 1 = 0;'
        ELSE
            N'SELECT object_name, rows_found FROM (' + @sql +
            N') AS findings ORDER BY object_name;'
    END;

EXEC sys.sp_executesql @sql;
