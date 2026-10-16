USE [llm_i9];

-- Checks every user table, including temporal history tables, for logically
-- queryable copies. Requires SELECT permission on every table and visibility
-- of all rows (including any protected by row-level security).
-- Transaction logs, deallocated pages, backups, and encoded/encrypted copies
-- cannot be exhaustively verified by a SELECT-only table scan.

DECLARE @sql nvarchar(max);

SELECT @sql =
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'SELECT N''' +
            REPLACE(s.name + N'.' + t.name, N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' AS d WHERE ' + COALESCE(p.predicate, N'1 = 0')
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
            N'(' +
            CASE
                WHEN c.system_type_id IN
                     (35, 99, 167, 175, 231, 239, 241, 98)
                THEN
                    N'CHARINDEX(@full_name, ' +
                    N'TRY_CONVERT(nvarchar(max), d.' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@email, ' +
                    N'TRY_CONVERT(nvarchar(max), d.' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@phone, ' +
                    N'TRY_CONVERT(nvarchar(max), d.' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0'
                ELSE N'1 = 0'
            END +
            CASE
                WHEN c.name COLLATE Latin1_General_100_CI_AS = N'customer_id'
                     AND c.system_type_id IN
                         (48, 52, 56, 127, 106, 108, 60, 122, 59, 62,
                          35, 99, 167, 175, 231, 239, 98)
                THEN
                    N' OR TRY_CONVERT(decimal(38, 10), ' +
                    N'TRY_CONVERT(nvarchar(max), d.' + QUOTENAME(c.name) +
                    N')) = @customer_id'
                ELSE N''
            END +
            N')'
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
                  (48, 52, 56, 127, 106, 108, 60, 122, 59, 62)
          )
      )
) AS p
WHERE t.is_ms_shipped = 0;

SELECT @sql =
    CASE
        WHEN @sql IS NULL THEN
            N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                     CAST(NULL AS bigint) AS rows_found
              WHERE 1 = 0;'
        ELSE
            N'SELECT object_name, rows_found FROM (' + @sql +
            N') AS results ORDER BY object_name;'
    END;

EXEC sys.sp_executesql
    @sql,
    N'@customer_id int,
      @full_name nvarchar(100),
      @email nvarchar(320),
      @phone nvarchar(100)',
    @customer_id = 42,
    @full_name = N'Subject_0000042',
    @email = N'subject42@example.invalid',
    @phone = N'+1-555-0000042';
