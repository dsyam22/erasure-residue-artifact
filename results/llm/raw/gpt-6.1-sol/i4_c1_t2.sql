/*
  Searches logical table contents, including temporal-history and CDC tables.
  Anonymized rows are not counted merely because their identifier remains 42.
  This does not inspect transaction logs, deallocated pages, or backups.
  Requires SELECT permission on every table and full metadata visibility.
*/
DECLARE @sql nvarchar(max);

SELECT @sql =
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'SELECT N''' +
            REPLACE(s.name + N'.' + t.name, N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            QUOTENAME(N'llm_i4') + N'.' +
            QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' WHERE ' + COALESCE(p.predicate, N'1 = 0')
        ),
        N' UNION ALL '
    ) WITHIN GROUP (ORDER BY s.name, t.name)
FROM llm_i4.sys.tables AS t
JOIN llm_i4.sys.schemas AS s
  ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CONVERT(nvarchar(max),
            N'(' +
            N'CHARINDEX(@original_name, ' + v.expression +
                N' COLLATE Latin1_General_100_BIN2) > 0 OR ' +
            N'CHARINDEX(@original_email, ' + v.expression +
                N' COLLATE Latin1_General_100_BIN2) > 0 OR ' +
            N'CHARINDEX(@original_phone, ' + v.expression +
                N' COLLATE Latin1_General_100_BIN2) > 0' +
            N')'
        ),
        N' OR '
    ) AS predicate
    FROM llm_i4.sys.columns AS c
    CROSS APPLY
    (
        SELECT
            N'CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N')'
                AS expression
        WHERE c.system_type_id IN
        (
            35, 99,             -- text, ntext
            167, 175, 231, 239, -- varchar, char, nvarchar, nchar
            241, 98,            -- xml, sql_variant
            34, 165, 173        -- image, varbinary, binary: UTF-16 representation
        )

        UNION ALL

        SELECT
            N'CONVERT(nvarchar(max), CONVERT(varchar(max), ' +
            QUOTENAME(c.name) + N'))'
        WHERE c.system_type_id IN (34, 165, 173)
    ) AS v
    WHERE c.object_id = t.object_id
) AS p;

SELECT @sql =
    CASE WHEN @sql IS NULL THEN
        N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                 CAST(NULL AS bigint) AS rows_found
          WHERE 1 = 0;'
    ELSE
        N'SELECT object_name, rows_found FROM (' + @sql +
        N') AS findings ORDER BY object_name;'
    END;

EXEC llm_i4.sys.sp_executesql
    @sql,
    N'@original_name nvarchar(100),
      @original_email nvarchar(320),
      @original_phone nvarchar(100)',
    @original_name  = N'Subject_0000042',
    @original_email = N'subject42@example.invalid',
    @original_phone = N'+1-555-0000042';
