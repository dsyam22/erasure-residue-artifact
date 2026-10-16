DECLARE @sql nvarchar(max);

SELECT @sql =
    STRING_AGG(
        CAST(
            N'SELECT N''' +
            REPLACE(s.name + N'.' + t.name, N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' WHERE ' + COALESCE(p.predicate_sql, N'1 = 0')
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
                WHEN c.name IN (N'customer_id', N'member_id')
                     AND c.system_type_id IN (48, 52, 56, 127, 106, 108)
                THEN QUOTENAME(c.name) + N' = 42'
                WHEN c.system_type_id IN (35, 99, 167, 175, 231, 239, 241)
                THEN
                    N'(' +
                    N'CHARINDEX(@full_name, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@email, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@phone, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0)'
            END
            AS nvarchar(max)
        ),
        N' OR '
    ) AS predicate_sql
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
) AS p;

-- Scan current tables, temporal history tables, CDC change tables,
-- and other catalog-visible tables directly, without double-counting history.
-- Counts describe logically queryable rows, not recoverable deleted pages,
-- transaction-log records, backups, or copies outside this database.
SELECT @sql =
    COALESCE(
        @sql + N' ORDER BY object_name;',
        N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                 CAST(NULL AS bigint) AS rows_found WHERE 1 = 0;'
    );

EXEC sys.sp_executesql
    @sql,
    N'@full_name nvarchar(100), @email nvarchar(200), @phone nvarchar(30)',
    @full_name = N'Subject_0000042',
    @email = N'subject42@example.invalid',
    @phone = N'+1-555-0000042';
