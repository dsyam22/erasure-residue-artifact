USE [llm_i4];

SET NOCOUNT ON;

DECLARE @sql nvarchar(max);

-- Scan every user table, including temporal history and CDC tables.
-- Retained identifiers alone do not count as residual original personal data.
SELECT @sql =
    STRING_AGG(
        CAST(
            N'SELECT N''' +
            REPLACE(s.name + N'.' + t.name, N'''', N'''''') +
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
            CASE
                WHEN c.system_type_id IN (34, 165, 173)
                THEN
                    N'(' +
                    N'CHARINDEX(CONVERT(varbinary(max), @original_name), CONVERT(varbinary(max), ' +
                        QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), @original_email), CONVERT(varbinary(max), ' +
                        QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), @original_phone), CONVERT(varbinary(max), ' +
                        QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), CONVERT(varchar(max), @original_name)), CONVERT(varbinary(max), ' +
                        QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), CONVERT(varchar(max), @original_email)), CONVERT(varbinary(max), ' +
                        QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), CONVERT(varchar(max), @original_phone)), CONVERT(varbinary(max), ' +
                        QUOTENAME(c.name) + N')) > 0)'
                ELSE
                    N'(' +
                    N'CHARINDEX(@original_name, CONVERT(nvarchar(max), ' +
                        QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@original_email, CONVERT(nvarchar(max), ' +
                        QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@original_phone, CONVERT(nvarchar(max), ' +
                        QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0)'
            END
            AS nvarchar(max)
        ),
        N' OR '
    ) AS predicate
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
      AND c.system_type_id IN
          (
              35, 99,              -- text, ntext
              167, 175, 231, 239,  -- varchar, char, nvarchar, nchar
              241, 98,             -- xml, sql_variant
              34, 165, 173         -- image, varbinary, binary
          )
) AS p
WHERE t.is_ms_shipped = 0;

SET @sql =
    CASE WHEN @sql IS NULL
         THEN N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                      CAST(NULL AS bigint) AS rows_found WHERE 1 = 0;'
         ELSE N'SELECT object_name, rows_found FROM (' + @sql +
              N') AS findings ORDER BY object_name;'
    END;

EXEC sys.sp_executesql
    @sql,
    N'@original_name nvarchar(100),
      @original_email nvarchar(320),
      @original_phone nvarchar(100)',
    @original_name  = N'Subject_0000042',
    @original_email = N'subject42@example.invalid',
    @original_phone = N'+1-555-0000042';
