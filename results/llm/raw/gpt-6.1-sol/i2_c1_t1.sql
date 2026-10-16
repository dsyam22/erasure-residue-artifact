/*
Checks every user table in llm_i2, including temporal history tables.
Counts each row once if it contains an original name, email, or phone
in a character/XML/sql_variant column, or customer_id = 42.

Requires SELECT permission on every checked table and unrestricted row
visibility. Transaction logs, deallocated pages, backups, and encrypted
payloads are not inspectable by this SELECT-only logical-data scan.
*/
DECLARE @sql nvarchar(max);

SELECT @sql =
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'SELECT N''' +
            REPLACE(s.name + N'.' + t.name, N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            N'[llm_i2].' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' AS d WHERE ' + COALESCE(p.predicate, N'1 = 0')
        ),
        N' UNION ALL '
    ) WITHIN GROUP (ORDER BY s.name, t.name)
FROM [llm_i2].sys.tables AS t
JOIN [llm_i2].sys.schemas AS s
  ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CONVERT(nvarchar(max),
            CASE
                WHEN c.system_type_id IN (35, 99, 167, 175, 231, 239, 241, 98)
                THEN
                    N'(CHARINDEX(N''Subject_0000042'', ' +
                    N'CONVERT(nvarchar(max), d.' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''subject42@example.invalid'', ' +
                    N'CONVERT(nvarchar(max), d.' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(N''+1-555-0000042'', ' +
                    N'CONVERT(nvarchar(max), d.' + QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0)'
            END +
            CASE
                WHEN c.name = N'customer_id'
                 AND c.system_type_id IN
                     (35, 48, 52, 56, 59, 60, 62, 99, 106, 108,
                      122, 127, 167, 175, 231, 239, 98)
                THEN
                    CASE
                        WHEN c.system_type_id IN
                             (35, 99, 167, 175, 231, 239, 241, 98)
                        THEN N' OR '
                        ELSE N''
                    END +
                    N'TRY_CONVERT(decimal(38, 10), CONVERT(nvarchar(max), d.' +
                    QUOTENAME(c.name) + N')) = 42'
                ELSE N''
            END
        ),
        N' OR '
    ) AS predicate
    FROM [llm_i2].sys.columns AS c
    WHERE c.object_id = t.object_id
      AND
      (
          c.system_type_id IN (35, 99, 167, 175, 231, 239, 241, 98)
          OR
          (
              c.name = N'customer_id'
              AND c.system_type_id IN
                  (48, 52, 56, 59, 60, 62, 106, 108, 122, 127)
          )
      )
) AS p
WHERE t.is_ms_shipped = 0;

-- An empty database must still produce exactly one, correctly shaped result set.
SELECT @sql = COALESCE(
    @sql + N' ORDER BY object_name;',
    N'SELECT CAST(NULL AS nvarchar(257)) AS object_name,
             CAST(NULL AS bigint) AS rows_found
      WHERE 1 = 0;'
);

EXEC sys.sp_executesql @sql;
