USE [llm_i6];

DECLARE @sql nvarchar(max);

-- Search every visible table and user-defined view, including temporal
-- history and CDC tables. Only the erased phone number is in scope.
-- Binary columns are searched for both single-byte and UTF-16 encodings.
SELECT @sql =
    STRING_AGG(
        CONVERT(nvarchar(max),
            N'SELECT N''' +
            REPLACE(QUOTENAME(s.name) + N'.' + QUOTENAME(o.name), N'''', N'''''') +
            N''' AS object_name, COUNT_BIG(*) AS rows_found FROM ' +
            QUOTENAME(s.name) + N'.' + QUOTENAME(o.name) +
            N' WHERE ' + COALESCE(p.predicate, N'1 = 0')
        ),
        N' UNION ALL '
    )
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
OUTER APPLY
(
    SELECT STRING_AGG(CONVERT(nvarchar(max),
        CASE
            WHEN c.system_type_id IN (34, 165, 173, 189)
            THEN
                N'(CHARINDEX(CONVERT(varbinary(max), ''+1-555-0000042''), ' +
                N'CONVERT(varbinary(max), ' + QUOTENAME(c.name) + N')) > 0 OR ' +
                N'CHARINDEX(CONVERT(varbinary(max), N''+1-555-0000042''), ' +
                N'CONVERT(varbinary(max), ' + QUOTENAME(c.name) + N')) > 0)'
            ELSE
                N'(CHARINDEX(N''+1-555-0000042'', ' +
                N'TRY_CONVERT(nvarchar(max), ' + QUOTENAME(c.name) +
                N') COLLATE Latin1_General_100_BIN2) > 0 OR ' +
                N'CHARINDEX(N''15550000042'', ' +
                N'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(' +
                N'TRY_CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N'), ' +
                N'N''-'', N''''), N''+'', N''''), N'' '', N''''), ' +
                N'N''('', N''''), N'')'', N''''), N''.'', N'''') ' +
                N'COLLATE Latin1_General_100_BIN2) > 0)'
        END
    ), N' OR ') AS predicate
    FROM sys.columns AS c
    WHERE c.object_id = o.object_id
      AND c.system_type_id IN
          (34, 35, 99, 165, 167, 173, 175, 189, 231, 239, 241, 98,
           48, 52, 56, 127, 106, 108)
) AS p
WHERE o.type = N'U'
   OR (o.type = N'V' AND o.is_ms_shipped = 0);

SELECT @sql =
    COALESCE(
        @sql,
        N'SELECT CONVERT(nvarchar(517), NULL) AS object_name,
                 CONVERT(bigint, NULL) AS rows_found WHERE 1 = 0'
    ) + N' ORDER BY object_name;';

EXEC sys.sp_executesql @sql;
