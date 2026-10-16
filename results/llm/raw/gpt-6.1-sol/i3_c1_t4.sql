USE [llm_i3];

DECLARE @sql nvarchar(max);

-- Scan all user tables, including temporal history tables.
-- Match original text wherever embedded in character/XML/sql_variant columns,
-- and match the subject's identifiers in customer_id/member_id columns.
SELECT @sql =
    COALESCE(
        STRING_AGG(
            CAST(
                N'SELECT N''' +
                REPLACE(QUOTENAME(s.name) + N'.' + QUOTENAME(t.name), N'''', N'''''') +
                N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
                QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
                N' AS src WHERE ' + COALESCE(p.predicate_sql, N'1 = 0')
                AS nvarchar(max)
            ),
            N' UNION ALL '
        ),
        N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                 CAST(NULL AS bigint) AS rows_found WHERE 1 = 0'
    )
FROM sys.tables AS t
JOIN sys.schemas AS s
  ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CAST(
            CASE
                WHEN c.name IN (N'customer_id', N'member_id')
                THEN
                    N'(TRY_CONVERT(decimal(38,10), src.' +
                    QUOTENAME(c.name) + N') = 42)'
                ELSE
                    N'(CHARINDEX(@full_name, TRY_CONVERT(nvarchar(max), src.' +
                    QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0' +
                    N' OR CHARINDEX(@email, TRY_CONVERT(nvarchar(max), src.' +
                    QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0' +
                    N' OR CHARINDEX(@phone, TRY_CONVERT(nvarchar(max), src.' +
                    QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0)'
            END
            AS nvarchar(max)
        ),
        N' OR '
    ) AS predicate_sql
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
      AND
      (
          c.name IN (N'customer_id', N'member_id')
          OR c.system_type_id IN
             (
                 35,  -- text
                 99,  -- ntext
                 167, -- varchar
                 175, -- char
                 231, -- nvarchar
                 239, -- nchar
                 241, -- xml
                 98   -- sql_variant
             )
      )
) AS p
WHERE t.is_ms_shipped = 0;

SET @sql = N'SELECT object_name, rows_found FROM (' +
           @sql + N') AS results ORDER BY object_name;';

EXEC sys.sp_executesql
    @sql,
    N'@full_name nvarchar(100), @email nvarchar(320), @phone nvarchar(100)',
    @full_name = N'Subject_0000042',
    @email = N'subject42@example.invalid',
    @phone = N'+1-555-0000042';
