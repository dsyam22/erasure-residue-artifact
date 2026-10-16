/*
  Read-only scan of accessible user tables, including temporal history tables.
  Counts each matching row once, even when multiple columns match.

  Matches:
    - customer_id = 42 in columns named customer_id;
    - the original name, email, or phone anywhere in textual/XML values,
      including JSON stored as text.

  Run with SELECT permission on every table and sufficient metadata visibility.
  Row-level security can hide matching rows.

  IMPORTANT: This checks queryable relational data, not physical erasure.
  Zero counts do not rule out recoverable data in deallocated pages, ghost
  records, transaction logs, backups, encrypted/encoded values, or opaque
  binary/CLR storage. A SELECT-only script cannot conclusively verify those.
*/
DECLARE @sql nvarchar(max);

SELECT @sql =
    STRING_AGG(
        CAST(
            N'SELECT N'''
            + REPLACE(QUOTENAME(s.name) + N'.' + QUOTENAME(t.name), N'''', N'''''')
            + N''' AS object_name, COUNT_BIG(*) AS rows_found FROM '
            + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
            + N' AS src WHERE '
            + COALESCE(p.predicate_sql, N'1 = 0')
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
            N'('
            + CASE
                WHEN c.name = N'customer_id'
                     AND c.system_type_id IN
                         (48, 52, 56, 127, 106, 108, 60, 122, 59, 62,
                          35, 99, 167, 175, 231, 239)
                THEN N'TRY_CONVERT(decimal(38,10), src.'
                     + QUOTENAME(c.name) + N') = 42 OR '
                ELSE N''
              END
            + CASE
                WHEN c.system_type_id IN (35, 99, 167, 175, 231, 239, 241)
                THEN
                    N'CHARINDEX(@original_name, TRY_CONVERT(nvarchar(max), src.'
                    + QUOTENAME(c.name)
                    + N') COLLATE Latin1_General_100_BIN2) > 0'
                    + N' OR CHARINDEX(@original_email, TRY_CONVERT(nvarchar(max), src.'
                    + QUOTENAME(c.name)
                    + N') COLLATE Latin1_General_100_BIN2) > 0'
                    + N' OR CHARINDEX(@original_phone, TRY_CONVERT(nvarchar(max), src.'
                    + QUOTENAME(c.name)
                    + N') COLLATE Latin1_General_100_BIN2) > 0'
                ELSE N'1 = 0'
              END
            + N')'
            AS nvarchar(max)
        ),
        N' OR '
    ) AS predicate_sql
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
      AND
      (
          c.system_type_id IN (35, 99, 167, 175, 231, 239, 241)
          OR
          (
              c.name = N'customer_id'
              AND c.system_type_id IN
                  (48, 52, 56, 127, 106, 108, 60, 122, 59, 62)
          )
      )
) AS p
WHERE t.is_ms_shipped = 0;

SELECT @sql =
    CASE
        WHEN @sql IS NULL
        THEN N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                      CAST(NULL AS bigint) AS rows_found
               WHERE 1 = 0;'
        ELSE N'SELECT object_name, rows_found FROM (' + @sql
             + N') AS findings ORDER BY object_name;'
    END;

EXEC sys.sp_executesql
    @sql,
    N'@original_name nvarchar(100),
      @original_email nvarchar(320),
      @original_phone nvarchar(100)',
    @original_name = N'Subject_0000042',
    @original_email = N'subject42@example.invalid',
    @original_phone = N'+1-555-0000042';
