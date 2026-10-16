USE [llm_i1];

-- Checks queryable table contents, including CDC change tables and history tables.
-- Zero counts do not prove physical erasure from transaction logs, deallocated
-- pages, backups, or other storage not exposed as queryable table contents.

DECLARE @sql nvarchar(max);

SELECT @sql =
    STRING_AGG(
        CAST(
            N'SELECT N''' +
            REPLACE(QUOTENAME(s.name) + N'.' + QUOTENAME(t.name), N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' WHERE ' + COALESCE(p.predicate, N'1 = 0')
            AS nvarchar(max)
        ),
        N' UNION ALL '
    ) WITHIN GROUP (ORDER BY s.name, t.name)
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CAST(
            N'(' +
            CASE
                WHEN c.system_type_id IN
                     (35, 99, 167, 175, 231, 239, 241, 98)
                THEN
                    N'CHARINDEX(N''Subject_0000042'', TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''subject42@example.invalid'', TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''+1-555-0000042'', TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0'
                ELSE N'1 = 0'
            END +
            CASE
                WHEN c.name COLLATE Latin1_General_100_CI_AS = N'customer_id'
                     AND c.system_type_id IN
                         (48, 52, 56, 127, 106, 108, 60, 122, 62, 59,
                          35, 99, 167, 175, 231, 239, 98)
                THEN
                    N' OR TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) + N') = N''42'''
                ELSE N''
            END +
            N')'
            AS nvarchar(max)
        ),
        N' OR '
    ) AS predicate
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
      AND
      (
          c.system_type_id IN (35, 99, 167, 175, 231, 239, 241, 98)
          OR
          (
              c.name COLLATE Latin1_General_100_CI_AS = N'customer_id'
              AND c.system_type_id IN
                  (48, 52, 56, 127, 106, 108, 60, 122, 62, 59)
          )
      )
) AS p;

SET @sql = CASE
    WHEN @sql IS NULL THEN
        N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                 CAST(NULL AS bigint) AS rows_found WHERE 1 = 0;'
    ELSE
        N'SELECT object_name, rows_found FROM (' + @sql +
        N') AS results ORDER BY object_name;'
END;

EXEC sys.sp_executesql @sql;
