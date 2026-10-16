USE [llm_i5];

DECLARE @sql nvarchar(max);

-- Check every user table, including temporal history tables.
-- Match original text values wherever they occur, and the original
-- customer_id in columns named customer_id.
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
            N'(' +
            CASE
                WHEN c.system_type_id IN
                     (35, 99, 167, 175, 231, 239, 241, 98)
                THEN
                    N'CHARINDEX(@full_name, ' + v.expression + N') > 0 OR ' +
                    N'CHARINDEX(@email, '     + v.expression + N') > 0 OR ' +
                    N'CHARINDEX(@phone, '     + v.expression + N') > 0'
                ELSE N'1 = 0'
            END +
            CASE
                WHEN c.name COLLATE Latin1_General_100_CI_AS = N'customer_id'
                THEN
                    N' OR TRY_CONVERT(decimal(38, 10), ' +
                    N'TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) + N')) = @customer_id'
                ELSE N''
            END +
            N')'
        ),
        N' OR '
    ) AS predicate
    FROM sys.columns AS c
    CROSS APPLY
    (
        SELECT
            N'(TRY_CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
            N') COLLATE Latin1_General_100_BIN2)' AS expression
    ) AS v
    WHERE c.object_id = t.object_id
      AND
      (
          c.system_type_id IN (35, 99, 167, 175, 231, 239, 241, 98)
          OR
          (
              c.name COLLATE Latin1_General_100_CI_AS = N'customer_id'
              AND c.system_type_id IN
                  (48, 52, 56, 59, 60, 62, 106, 108, 122, 127)
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
            N'SELECT object_name, rows_found FROM (' +
            @sql +
            N') AS findings ORDER BY object_name;'
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
