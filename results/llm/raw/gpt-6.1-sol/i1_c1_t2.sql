/*
  Checks persisted, queryable user tables, including temporal history and CDC
  tables, for the original name, email and phone, and customer_id = 42.

  This is a logical-data check, not proof of physical erasure. SELECT queries
  cannot establish absence from deallocated pages, ghost records, transaction
  logs, backups, or other physical remnants. Encrypted or otherwise transformed
  copies cannot be reliably identified without their decoding information.

  Requires SELECT permission on every table checked and metadata visibility.
  Dynamic execution below executes SELECT statements only.
*/
DECLARE @sql nvarchar(max);

SELECT @sql =
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'SELECT N''' +
            REPLACE(s.name + N'.' + t.name, N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            N'[llm_i1].' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' WHERE ' + COALESCE(p.predicate, N'1 = 0')
        ),
        N' UNION ALL '
    )
FROM llm_i1.sys.tables AS t
JOIN llm_i1.sys.schemas AS s
  ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(CONVERT(nvarchar(max), q.predicate), N' OR ') AS predicate
    FROM
    (
        SELECT
            CASE
                -- Character, XML and sql_variant values.
                WHEN c.system_type_id IN (35, 99, 167, 175, 231, 239, 241, 98)
                THEN
                    N'(CHARINDEX(@full_name, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@email, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@phone, CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0' +
                    CASE WHEN c.name = N'customer_id'
                         THEN N' OR TRY_CONVERT(decimal(38,10), CONVERT(nvarchar(max), ' +
                              QUOTENAME(c.name) + N')) = 42'
                         ELSE N''
                    END + N')'

                -- Search binary values for both UTF-16 and ASCII encodings.
                WHEN c.system_type_id IN (34, 165, 173, 189)
                THEN
                    N'(CHARINDEX(CONVERT(varbinary(max), @full_name), CONVERT(varbinary(max), ' +
                    QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), @email), CONVERT(varbinary(max), ' +
                    QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), @phone), CONVERT(varbinary(max), ' +
                    QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), CONVERT(varchar(max), @full_name)), CONVERT(varbinary(max), ' +
                    QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), CONVERT(varchar(max), @email)), CONVERT(varbinary(max), ' +
                    QUOTENAME(c.name) + N')) > 0 OR ' +
                    N'CHARINDEX(CONVERT(varbinary(max), CONVERT(varchar(max), @phone)), CONVERT(varbinary(max), ' +
                    QUOTENAME(c.name) + N')) > 0)'

                -- Avoid treating unrelated numeric values of 42 as this customer.
                WHEN c.name = N'customer_id'
                 AND c.system_type_id IN (48, 52, 56, 59, 60, 62, 106, 108, 122, 127)
                THEN N'(' + QUOTENAME(c.name) + N' = 42)'
            END AS predicate
        FROM llm_i1.sys.columns AS c
        WHERE c.object_id = t.object_id
    ) AS q
    WHERE q.predicate IS NOT NULL
) AS p
WHERE t.is_ms_shipped = 0;

SELECT @sql =
    CASE
        WHEN @sql IS NULL
        THEN N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                      CAST(NULL AS bigint) AS rows_found
               WHERE 1 = 0;'
        ELSE N'SELECT object_name, rows_found FROM (' + @sql +
             N') AS findings ORDER BY object_name;'
    END;

EXEC llm_i1.sys.sp_executesql
    @sql,
    N'@full_name nvarchar(100), @email nvarchar(320), @phone nvarchar(100)',
    @full_name = N'Subject_0000042',
    @email = N'subject42@example.invalid',
    @phone = N'+1-555-0000042';
