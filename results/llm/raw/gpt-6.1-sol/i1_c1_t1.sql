USE [llm_i1];

SET NOCOUNT ON;

/*
  Checks live, SELECT-visible rows in every table exposed by sys.tables,
  including temporal history and CDC tables.

  A row matches if any searchable column contains an original name, email,
  or phone, or has the exact textual value '42'.

  This does not inspect deallocated pages, ghost records, transaction logs,
  backups, inaccessible rows, encrypted plaintext, or encoded/compressed data.
  Run with SELECT permission on every table and unrestricted row visibility.
*/
DECLARE @sql nvarchar(max);

SELECT @sql =
    STRING_AGG(
        CAST(
            N'SELECT N''' +
            REPLACE(s.name + N'.' + t.name, N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
            N' AS src WHERE ' + COALESCE(p.predicate, N'1 = 0')
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
            N'(' + v.expression + N' COLLATE Latin1_General_100_BIN2 IN ' +
            N'(N''42'', N''Subject_0000042'', ' +
            N'N''subject42@example.invalid'', N''+1-555-0000042'')' +
            N' OR CHARINDEX(N''Subject_0000042'', ' +
            v.expression + N' COLLATE Latin1_General_100_BIN2) > 0' +
            N' OR CHARINDEX(N''subject42@example.invalid'', ' +
            v.expression + N' COLLATE Latin1_General_100_BIN2) > 0' +
            N' OR CHARINDEX(N''+1-555-0000042'', ' +
            v.expression + N' COLLATE Latin1_General_100_BIN2) > 0)'
            AS nvarchar(max)
        ),
        N' OR '
    ) AS predicate
    FROM sys.columns AS c
    CROSS APPLY
    (
        SELECT
            N'TRY_CONVERT(nvarchar(max), src.' +
            QUOTENAME(c.name) + N')' AS expression
        WHERE c.system_type_id IN
        (
            34, 35, 36, 40, 41, 42, 43, 48, 52, 56, 58,
            59, 60, 61, 62, 98, 99, 104, 106, 108, 122,
            127, 165, 167, 173, 175, 189, 231, 239, 241
        )

        UNION ALL

        /* Also inspect binary values interpreted as single-byte text. */
        SELECT
            N'TRY_CONVERT(nvarchar(max), TRY_CONVERT(varchar(max), src.' +
            QUOTENAME(c.name) + N'))'
        WHERE c.system_type_id IN (34, 165, 173, 189)

        UNION ALL

        /* SQL Server's built-in CLR types expose textual representations. */
        SELECT
            N'TRY_CONVERT(nvarchar(max), src.' +
            QUOTENAME(c.name) + N'.ToString())'
        WHERE c.system_type_id = 240
          AND c.user_type_id IN
          (
              SELECT ty.user_type_id
              FROM sys.types AS ty
              WHERE ty.is_assembly_type = 1
                AND ty.schema_id = SCHEMA_ID(N'sys')
                AND ty.name IN (N'geography', N'geometry', N'hierarchyid')
          )
    ) AS v
    WHERE c.object_id = t.object_id
) AS p;

SELECT @sql =
    CASE
        WHEN @sql IS NULL THEN
            N'SELECT CAST(NULL AS nvarchar(257)) AS object_name,
                     CAST(NULL AS bigint) AS rows_found
              WHERE 1 = 0;'
        ELSE
            N'SELECT object_name, rows_found FROM (' + @sql +
            N') AS findings ORDER BY object_name;'
    END;

EXEC sys.sp_executesql @sql;
