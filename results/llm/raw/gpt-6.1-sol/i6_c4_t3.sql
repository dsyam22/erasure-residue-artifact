USE [llm_i6];

DECLARE @sql nvarchar(max);
DECLARE @phone nvarchar(60) = N'+1-555-0000042';

-- Scan every accessible table, including CDC and temporal history tables.
-- Count a matching row only once, even if multiple columns match.
SELECT @sql = STRING_AGG(
    CONVERT(nvarchar(max),
        N'SELECT N''' +
        REPLACE(s.name + N'.' + t.name, N'''', N'''''') +
        N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
        QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
        N' WHERE ' + COALESCE(p.predicate, N'1 = 0')),
    N' UNION ALL ')
FROM sys.tables AS t
JOIN sys.schemas AS s
  ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CONVERT(nvarchar(max),
            CASE
                WHEN c.system_type_id IN (165, 173, 34)
                THEN
                    N'(CHARINDEX(CONVERT(varbinary(max), @phone), ' +
                    N'CONVERT(varbinary(max), ' + QUOTENAME(c.name) + N')) > 0' +
                    N' OR CHARINDEX(CONVERT(varbinary(max), CONVERT(varchar(60), @phone)), ' +
                    N'CONVERT(varbinary(max), ' + QUOTENAME(c.name) + N')) > 0)'
                ELSE
                    N'CHARINDEX(@phone COLLATE Latin1_General_100_BIN2, ' +
                    N'TRY_CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0'
            END),
        N' OR ') AS predicate
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
      AND c.system_type_id IN
          (
              35, 99,             -- text, ntext
              167, 175, 231, 239, -- varchar, char, nvarchar, nchar
              165, 173, 34,       -- varbinary, binary, image
              241, 98            -- XML, sql_variant
          )
) AS p;

SELECT @sql =
    CASE WHEN @sql IS NULL
         THEN N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                       CAST(NULL AS bigint) AS rows_found WHERE 1 = 0;'
         ELSE N'SELECT object_name, rows_found FROM (' + @sql +
              N') AS findings ORDER BY object_name;'
    END;

EXEC sys.sp_executesql
    @sql,
    N'@phone nvarchar(60)',
    @phone = @phone;
