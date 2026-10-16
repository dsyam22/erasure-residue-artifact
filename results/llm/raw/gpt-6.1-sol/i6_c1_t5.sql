DECLARE @phone nvarchar(100) = N'+1-555-0000042';
DECLARE @sql nvarchar(max);

-- Inspect every user table, including temporal history tables, and every
-- character, XML, sql_variant, and binary column that could hold the phone.
SELECT @sql =
    STRING_AGG(
        CAST(
            N'SELECT N''' +
            REPLACE(s.name + N'.' + t.name, N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            QUOTENAME(N'llm_i6') + N'.' +
            QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' WHERE ' + COALESCE(p.predicate, N'1 = 0')
            AS nvarchar(max)
        ),
        N' UNION ALL '
    )
FROM [llm_i6].sys.tables AS t
JOIN [llm_i6].sys.schemas AS s
    ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CAST(
            CASE
                WHEN c.system_type_id IN (34, 165, 173) THEN
                    N'(CHARINDEX(CONVERT(varbinary(max), CONVERT(varchar(100), @phone)), ' +
                    N'CONVERT(varbinary(max), ' + QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), @phone), ' +
                    N'CONVERT(varbinary(max), ' + QUOTENAME(c.name) + N')) > 0)'
                ELSE
                    N'CHARINDEX(@phone COLLATE Latin1_General_100_BIN2, ' +
                    N'CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0'
            END
            AS nvarchar(max)
        ),
        N' OR '
    ) AS predicate
    FROM [llm_i6].sys.columns AS c
    WHERE c.object_id = t.object_id
      AND c.system_type_id IN
          (
              35, 99,           -- text, ntext
              167, 175,         -- varchar, char
              231, 239,         -- nvarchar, nchar
              241,              -- xml
              98,               -- sql_variant
              34, 165, 173      -- image, varbinary, binary
          )
) AS p
WHERE t.is_ms_shipped = 0;

SELECT @sql =
    N'SELECT object_name, rows_found FROM (' +
    COALESCE(
        @sql,
        N'SELECT CAST(NULL AS nvarchar(257)) AS object_name, ' +
        N'CAST(0 AS bigint) AS rows_found WHERE 1 = 0'
    ) +
    N') AS findings ORDER BY object_name;';

EXEC sys.sp_executesql
    @sql,
    N'@phone nvarchar(100)',
    @phone = @phone;
