DECLARE @sql nvarchar(max);

;WITH predicates AS
(
    SELECT
        c.object_id,
        STRING_AGG(
            CONVERT(nvarchar(max),
                CASE
                    WHEN c.system_type_id IN (34, 165, 173) THEN
                        N'CHARINDEX(@phone, CONVERT(nvarchar(max), '
                        + QUOTENAME(c.name)
                        + N') COLLATE Latin1_General_100_BIN2) > 0 OR '
                        + N'CHARINDEX(@phone, CONVERT(varchar(max), '
                        + QUOTENAME(c.name)
                        + N') COLLATE Latin1_General_100_BIN2) > 0'
                    ELSE
                        N'CHARINDEX(@phone, TRY_CONVERT(nvarchar(max), '
                        + QUOTENAME(c.name)
                        + N') COLLATE Latin1_General_100_BIN2) > 0'
                END
            ),
            N' OR '
        ) AS predicate_sql
    FROM [llm_i6].sys.columns AS c
    WHERE c.system_type_id IN
    (
        35, 99,             -- text, ntext
        167, 175, 231, 239, -- varchar, char, nvarchar, nchar
        98, 241,            -- sql_variant, xml
        34, 165, 173        -- image, varbinary, binary
    )
    GROUP BY c.object_id
)
SELECT @sql =
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'SELECT N'''
            + REPLACE(s.name + N'.' + t.name, N'''', N'''''')
            + N''' AS object_name, COUNT_BIG(*) AS rows_found FROM '
            + N'[llm_i6].' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
            + N' WHERE (' + COALESCE(p.predicate_sql, N'1 = 0') + N')'
        ),
        N' UNION ALL '
    )
FROM [llm_i6].sys.tables AS t
JOIN [llm_i6].sys.schemas AS s
    ON s.schema_id = t.schema_id
LEFT JOIN predicates AS p
    ON p.object_id = t.object_id;

SELECT @sql =
    COALESCE(
        @sql,
        N'SELECT CAST(NULL AS nvarchar(517)) AS object_name,
                 CAST(NULL AS bigint) AS rows_found WHERE 1 = 0'
    ) + N' ORDER BY object_name;';

EXEC sys.sp_executesql
    @sql,
    N'@phone nvarchar(32)',
    @phone = N'+1-555-0000042';
