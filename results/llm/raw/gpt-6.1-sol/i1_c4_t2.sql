/*
Checks accessible table rows, including separately stored temporal-history,
CDC, and application audit/archive tables.

This is a logical row scan, not proof of physical erasure. Deleted-page
remnants, transaction logs, backups, snapshots, encrypted values without
decryption access, and rows hidden by permissions or row-level security
cannot be conclusively checked by this scan.

A match is an original name, email, or phone occurring in a supported column,
or the original customer_id in a column named customer_id.
*/
DECLARE @sql nvarchar(max);

SELECT @sql =
    STRING_AGG(
        CAST(
            N'SELECT N''' +
            REPLACE(QUOTENAME(s.name) + N'.' + QUOTENAME(t.name), N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' WHERE ' + COALESCE(pred.predicate_sql, N'1 = 0')
            AS nvarchar(max)
        ),
        N' UNION ALL '
    )
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CAST(
            N'(' +
            CASE
                WHEN c.name = N'customer_id'
                     AND c.system_type_id IN
                         (36, 48, 52, 56, 59, 60, 62, 98, 104, 106,
                          108, 122, 127, 167, 175, 231, 239)
                THEN
                    N'TRY_CONVERT(decimal(38,10), ' +
                    QUOTENAME(c.name) + N') = 42 OR '
                ELSE N''
            END +
            CASE
                WHEN c.system_type_id IN (34, 165, 173, 189)
                THEN
                    N'CHARINDEX(@full_name, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@email, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@phone, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@full_name, CONVERT(nvarchar(max), CONVERT(varchar(max), ' +
                    QUOTENAME(c.name) + N')) COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@email, CONVERT(nvarchar(max), CONVERT(varchar(max), ' +
                    QUOTENAME(c.name) + N')) COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@phone, CONVERT(nvarchar(max), CONVERT(varchar(max), ' +
                    QUOTENAME(c.name) + N')) COLLATE Latin1_General_100_BIN2) > 0'
                ELSE
                    N'CHARINDEX(@full_name, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@email, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@phone, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) + N') COLLATE Latin1_General_100_BIN2) > 0'
            END +
            N')'
            AS nvarchar(max)
        ),
        N' OR '
    ) AS predicate_sql
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
      AND c.is_dropped_ledger_column = 0
      AND c.encryption_type IS NULL
      AND
      (
          c.system_type_id IN
              (34, 35, 98, 99, 165, 167, 173, 175, 189, 231, 239, 241)
          OR
          (
              c.name = N'customer_id'
              AND c.system_type_id IN
                  (36, 48, 52, 56, 59, 60, 62, 104, 106, 108, 122, 127)
          )
      )
) AS pred
WHERE t.is_dropped_ledger_table = 0;

SELECT @sql =
    CASE
        WHEN @sql IS NULL
        THEN N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                     CAST(NULL AS bigint) AS rows_found WHERE 1 = 0;'
        ELSE N'SELECT object_name, rows_found FROM (' +
             @sql + N') AS results ORDER BY object_name;'
    END;

EXEC sys.sp_executesql
    @sql,
    N'@full_name nvarchar(100), @email nvarchar(320), @phone nvarchar(100)',
    @full_name = N'Subject_0000042',
    @email = N'subject42@example.invalid',
    @phone = N'+1-555-0000042';
