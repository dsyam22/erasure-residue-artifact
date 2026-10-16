USE [llm_i2];

-- Checks current user tables and temporal history tables.
-- This checks queryable row data, not transaction logs, backups, or deallocated pages.
DECLARE @sql nvarchar(max);

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
                WHEN c.system_type_id IN
                     (35, 99, 167, 175, 231, 239, 241, 98)
                THEN
                    N'(CHARINDEX(@full_name, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0' +
                    N' OR CHARINDEX(@email, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0' +
                    N' OR CHARINDEX(@phone, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0' +
                    CASE WHEN c.name = N'customer_id'
                         THEN N' OR TRY_CONVERT(int, ' +
                              QUOTENAME(c.name) + N') = @customer_id'
                         ELSE N''
                    END + N')'
                WHEN c.name = N'customer_id'
                     AND c.system_type_id IN
                         (48, 52, 56, 59, 60, 62, 106, 108, 122, 127)
                THEN QUOTENAME(c.name) + N' = @customer_id'
            END AS nvarchar(max)
        ),
        N' OR '
    ) AS predicate
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
) AS p
WHERE t.is_ms_shipped = 0;

SELECT @sql =
    CASE WHEN @sql IS NULL
         THEN N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                       CAST(NULL AS bigint) AS rows_found
                WHERE 1 = 0;'
         ELSE N'SELECT object_name, rows_found FROM (' + @sql +
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
