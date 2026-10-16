USE [llm_i8];

-- Scope: current, SELECT-visible rows in all user tables, including any
-- temporal-history and CDC tables exposed in sys.tables.
-- This is not proof of physical erasure: deleted-page remnants, transaction
-- logs, backups, encrypted values, and encoded/transformed copies are not
-- exhaustively searchable through ordinary SELECT statements.
-- Run with permission to read every table and bypass applicable row-level
-- security. Concurrent writes can affect the results.

DECLARE @sql nvarchar(max);

SELECT @sql =
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'SELECT N''' +
            REPLACE(QUOTENAME(s.name) + N'.' + QUOTENAME(t.name), N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' WHERE ' + COALESCE(p.predicate_sql, N'1 = 0')
        ),
        N' UNION ALL '
    )
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(
        CONVERT(nvarchar(max),
            CASE
                WHEN c.system_type_id IN
                     (35, 99, 167, 175, 231, 239, 241, 98)
                THEN
                    N'(' +
                    N'CHARINDEX(@full_name, TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@email, TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                    N'CHARINDEX(@phone, TRY_CONVERT(nvarchar(max), ' +
                    QUOTENAME(c.name) +
                    N') COLLATE Latin1_General_100_BIN2) > 0' +
                    CASE WHEN c.name = N'customer_id'
                         THEN N' OR TRY_CONVERT(decimal(38,10), TRY_CONVERT(nvarchar(max), ' +
                              QUOTENAME(c.name) + N')) = @customer_id'
                         ELSE N''
                    END +
                    N')'
                WHEN c.name = N'customer_id'
                     AND c.system_type_id IN
                         (48, 52, 56, 59, 60, 62, 104, 106, 108, 122, 127)
                THEN QUOTENAME(c.name) + N' = @customer_id'
                WHEN c.system_type_id IN (34, 165, 173)
                THEN
                    N'(' +
                    N'CHARINDEX(@name_utf8_hex, CONVERT(varchar(max), ' +
                    QUOTENAME(c.name) + N', 2)) > 0 OR ' +
                    N'CHARINDEX(@email_utf8_hex, CONVERT(varchar(max), ' +
                    QUOTENAME(c.name) + N', 2)) > 0 OR ' +
                    N'CHARINDEX(@phone_utf8_hex, CONVERT(varchar(max), ' +
                    QUOTENAME(c.name) + N', 2)) > 0 OR ' +
                    N'CHARINDEX(@name_utf16_hex, CONVERT(varchar(max), ' +
                    QUOTENAME(c.name) + N', 2)) > 0 OR ' +
                    N'CHARINDEX(@email_utf16_hex, CONVERT(varchar(max), ' +
                    QUOTENAME(c.name) + N', 2)) > 0 OR ' +
                    N'CHARINDEX(@phone_utf16_hex, CONVERT(varchar(max), ' +
                    QUOTENAME(c.name) + N', 2)) > 0)'
            END
        ),
        N' OR '
    ) AS predicate_sql
    FROM sys.columns AS c
    WHERE c.object_id = t.object_id
      AND c.encryption_type IS NULL
) AS p
WHERE t.is_ms_shipped = 0;

SELECT @sql =
    CASE WHEN @sql IS NULL
         THEN N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                       CAST(NULL AS bigint) AS rows_found WHERE 1 = 0;'
         ELSE N'SELECT object_name, rows_found FROM (' + @sql +
              N') AS results ORDER BY object_name;'
    END;

DECLARE
    @name_utf8_hex varchar(max),
    @email_utf8_hex varchar(max),
    @phone_utf8_hex varchar(max),
    @name_utf16_hex varchar(max),
    @email_utf16_hex varchar(max),
    @phone_utf16_hex varchar(max);

SELECT
    @name_utf8_hex = CONVERT(varchar(max), CONVERT(varbinary(max), 'Subject_0000042'), 2),
    @email_utf8_hex = CONVERT(varchar(max), CONVERT(varbinary(max), 'subject42@example.invalid'), 2),
    @phone_utf8_hex = CONVERT(varchar(max), CONVERT(varbinary(max), '+1-555-0000042'), 2),
    @name_utf16_hex = CONVERT(varchar(max), CONVERT(varbinary(max), N'Subject_0000042'), 2),
    @email_utf16_hex = CONVERT(varchar(max), CONVERT(varbinary(max), N'subject42@example.invalid'), 2),
    @phone_utf16_hex = CONVERT(varchar(max), CONVERT(varbinary(max), N'+1-555-0000042'), 2);

-- The dynamically executed batch contains SELECT statements only.
EXEC sys.sp_executesql
    @sql,
    N'@customer_id int,
      @full_name nvarchar(100),
      @email nvarchar(320),
      @phone nvarchar(100),
      @name_utf8_hex varchar(max),
      @email_utf8_hex varchar(max),
      @phone_utf8_hex varchar(max),
      @name_utf16_hex varchar(max),
      @email_utf16_hex varchar(max),
      @phone_utf16_hex varchar(max)',
    @customer_id = 42,
    @full_name = N'Subject_0000042',
    @email = N'subject42@example.invalid',
    @phone = N'+1-555-0000042',
    @name_utf8_hex = @name_utf8_hex,
    @email_utf8_hex = @email_utf8_hex,
    @phone_utf8_hex = @phone_utf8_hex,
    @name_utf16_hex = @name_utf16_hex,
    @email_utf16_hex = @email_utf16_hex,
    @phone_utf16_hex = @phone_utf16_hex;
