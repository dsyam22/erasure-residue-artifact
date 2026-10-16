USE [llm_i2];

SET NOCOUNT ON;

DECLARE @sql nvarchar(max);

-- Check every user table, including temporal history tables.
-- Count each matching row once, even if several columns match.
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
                WHEN c.name = N'customer_id' THEN
                    N'TRY_CONVERT(bigint, TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) + N')) = 42'
                ELSE N'1 = 0'
            END +
            CASE
                WHEN c.system_type_id IN
                     (35, 99, 167, 175, 231, 239, 241, 98)
                THEN
                    N' OR CHARINDEX(N''Subject_0000042'', ' +
                    N'TRY_CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0' +
                    N' OR CHARINDEX(N''subject42@example.invalid'', ' +
                    N'TRY_CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0' +
                    N' OR CHARINDEX(N''+1-555-0000042'', ' +
                    N'TRY_CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0'
                WHEN c.system_type_id IN (34, 165, 173)
                THEN
                    N' OR CHARINDEX(CONVERT(varbinary(max), ''Subject_0000042''), ' +
                    N'CONVERT(varbinary(max), ' + QUOTENAME(c.name) + N')) > 0' +
                    N' OR CHARINDEX(CONVERT(varbinary(max), ''subject42@example.invalid''), ' +
                    N'CONVERT(varbinary(max), ' + QUOTENAME(c.name) + N')) > 0' +
                    N' OR CHARINDEX(CONVERT(varbinary(max), ''+1-555-0000042''), ' +
                    N'CONVERT(varbinary(max), ' + QUOTENAME(c.name) + N')) > 0' +
                    N' OR CHARINDEX(CONVERT(varbinary(max), N''Subject_0000042''), ' +
                    N'CONVERT(varbinary(max), ' + QUOTENAME(c.name) + N')) > 0' +
                    N' OR CHARINDEX(CONVERT(varbinary(max), N''subject42@example.invalid''), ' +
                    N'CONVERT(varbinary(max), ' + QUOTENAME(c.name) + N')) > 0' +
                    N' OR CHARINDEX(CONVERT(varbinary(max), N''+1-555-0000042''), ' +
                    N'CONVERT(varbinary(max), ' + QUOTENAME(c.name) + N')) > 0'
                ELSE N''
            END
        ),
        N' OR '
    ) AS predicate
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
      AND (
          c.name = N'customer_id'
          OR c.system_type_id IN
             (35, 99, 167, 175, 231, 239, 241, 98, 34, 165, 173)
      )
) AS p
WHERE t.is_ms_shipped = 0;

SELECT @sql =
    CASE WHEN @sql IS NULL THEN
        N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                 CAST(NULL AS bigint) AS rows_found WHERE 1 = 0;'
    ELSE
        N'SELECT object_name, rows_found FROM (' + @sql +
        N') AS findings ORDER BY object_name;'
    END;

-- Scope: accessible, current logical table contents (including history).
-- Does not inspect backups, transaction logs, deallocated pages, encrypted
-- payloads, external storage, or rows hidden by permissions/security policies.
EXEC sys.sp_executesql @sql;
