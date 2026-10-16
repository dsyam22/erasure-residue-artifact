USE [llm_i8];

-- Checks query-visible rows in all tables, including temporal history and CDC
-- tables, and in materialized (indexed) views. Requires SELECT permission on
-- every checked object and metadata visibility for the entire database.
--
-- This is not a forensic erasure certification: SELECT cannot comprehensively
-- inspect deleted/ghost records, deallocated pages, transaction-log remnants,
-- backups, FILESTREAM remnants, or opaque/encrypted application payloads.
-- Row-level security and Always Encrypted can also prevent complete inspection.
--
-- Text searches are case-sensitive substring searches for the original name,
-- email and phone. Columns named customer_id are additionally checked for 42.
-- Binary columns are searched as both Unicode and single-byte text.

DECLARE @sql nvarchar(max);

;WITH objects_to_check AS
(
    SELECT t.object_id, t.schema_id, t.name
    FROM sys.tables AS t

    UNION ALL

    SELECT v.object_id, v.schema_id, v.name
    FROM sys.views AS v
    WHERE EXISTS
    (
        SELECT 1
        FROM sys.indexes AS i
        WHERE i.object_id = v.object_id
          AND i.index_id = 1
    )
),
column_expressions AS
(
    SELECT
        o.object_id,
        o.schema_id,
        o.name,
        c.column_id,
        c.name AS column_name,
        c.system_type_id,
        CASE
            WHEN c.system_type_id IN
                 (35, 99, 167, 175, 231, 239, 241, 98)
            THEN
                N'TRY_CONVERT(nvarchar(max), d.' + QUOTENAME(c.name) + N')'
            WHEN c.system_type_id IN (34, 165, 173, 189)
            THEN
                N'TRY_CONVERT(nvarchar(max), CONVERT(varbinary(max), d.'
                + QUOTENAME(c.name) + N'))'
            WHEN ty.name IN (N'geometry', N'geography', N'hierarchyid')
                 AND ty.is_assembly_type = 1
            THEN
                N'CONVERT(nvarchar(max), d.' + QUOTENAME(c.name)
                + N'.ToString())'
        END AS text_expression,
        CASE
            WHEN c.name = N'customer_id'
                 AND c.system_type_id IN
                     (48, 52, 56, 127, 106, 108, 60, 122, 59, 62,
                      35, 99, 167, 175, 231, 239, 98)
            THEN
                N'TRY_CONVERT(decimal(38,10), d.'
                + QUOTENAME(c.name) + N') = 42'
        END AS id_predicate
    FROM objects_to_check AS o
    JOIN sys.columns AS c
      ON c.object_id = o.object_id
    JOIN sys.types AS ty
      ON ty.user_type_id = c.user_type_id
),
column_predicates AS
(
    SELECT
        object_id,
        column_id,
        CONVERT(nvarchar(max),
            CASE WHEN text_expression IS NOT NULL THEN
                N'CHARINDEX(@subject_name, '
                + text_expression + N' COLLATE Latin1_General_100_BIN2) > 0'
                + N' OR CHARINDEX(@subject_email, '
                + text_expression + N' COLLATE Latin1_General_100_BIN2) > 0'
                + N' OR CHARINDEX(@subject_phone, '
                + text_expression + N' COLLATE Latin1_General_100_BIN2) > 0'
            ELSE N'1 = 0' END
            + CASE WHEN id_predicate IS NOT NULL
                THEN N' OR ' + id_predicate ELSE N'' END
            + CASE WHEN system_type_id IN (34, 165, 173, 189) THEN
                N' OR CHARINDEX(@subject_name, CONVERT(nvarchar(max),'
                + N' CONVERT(varchar(max), CONVERT(varbinary(max), d.'
                + QUOTENAME(column_name)
                + N'))) COLLATE Latin1_General_100_BIN2) > 0'
                + N' OR CHARINDEX(@subject_email, CONVERT(nvarchar(max),'
                + N' CONVERT(varchar(max), CONVERT(varbinary(max), d.'
                + QUOTENAME(column_name)
                + N'))) COLLATE Latin1_General_100_BIN2) > 0'
                + N' OR CHARINDEX(@subject_phone, CONVERT(nvarchar(max),'
                + N' CONVERT(varchar(max), CONVERT(varbinary(max), d.'
                + QUOTENAME(column_name)
                + N'))) COLLATE Latin1_General_100_BIN2) > 0'
            ELSE N'' END
        ) AS predicate
    FROM column_expressions
),
object_predicates AS
(
    SELECT
        object_id,
        STRING_AGG(CONVERT(nvarchar(max), N'(' + predicate + N')'), N' OR ')
            WITHIN GROUP (ORDER BY column_id) AS predicate
    FROM column_predicates
    GROUP BY object_id
)
SELECT @sql =
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'SELECT N'''
            + REPLACE(s.name + N'.' + o.name, N'''', N'''''')
            + N''' AS object_name, COUNT_BIG(*) AS rows_found FROM '
            + QUOTENAME(s.name) + N'.' + QUOTENAME(o.name)
            + N' AS d WHERE ' + COALESCE(p.predicate, N'1 = 0')
        ),
        N' UNION ALL '
    )
FROM objects_to_check AS o
JOIN sys.schemas AS s
  ON s.schema_id = o.schema_id
LEFT JOIN object_predicates AS p
  ON p.object_id = o.object_id;

SELECT @sql =
    CASE WHEN @sql IS NULL THEN
        N'SELECT CONVERT(nvarchar(517), NULL) AS object_name,'
        + N' CONVERT(bigint, NULL) AS rows_found WHERE 1 = 0;'
    ELSE
        N'SELECT object_name, rows_found FROM (' + @sql
        + N') AS findings ORDER BY object_name;'
    END;

EXEC sys.sp_executesql
    @sql,
    N'@subject_name nvarchar(100),
      @subject_email nvarchar(320),
      @subject_phone nvarchar(100)',
    @subject_name = N'Subject_0000042',
    @subject_email = N'subject42@example.invalid',
    @subject_phone = N'+1-555-0000042';
