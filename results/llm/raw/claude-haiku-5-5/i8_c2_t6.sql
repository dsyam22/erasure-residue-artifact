SET NOCOUNT ON;

DECLARE @p1 nvarchar(200) = N'%Subject[_]0000042%';
DECLARE @p2 nvarchar(200) = N'%subject42@example.invalid%';
DECLARE @p3 nvarchar(200) = N'%+1-555-0000042%';
DECLARE @union nvarchar(max);

;WITH tbl AS (
    SELECT o.object_id,
           QUOTENAME(s.name) + N'.' + QUOTENAME(o.name) AS fq,
           s.name + N'.' + o.name AS nm
    FROM sys.objects AS o
    JOIN sys.schemas AS s ON s.schema_id = o.schema_id
    WHERE o.type = 'U'
),
pred AS (
    SELECT tb.object_id,
           STRING_AGG(CAST(
               N'(' + QUOTENAME(c.name) + N' LIKE @p1 OR '
                    + QUOTENAME(c.name) + N' LIKE @p2 OR '
                    + QUOTENAME(c.name) + N' LIKE @p3)' AS nvarchar(max)),
               N' OR ') AS wh
    FROM tbl AS tb
    JOIN sys.columns AS c ON c.object_id = tb.object_id
    WHERE c.system_type_id IN (167, 175, 231, 239)  -- varchar, char, nvarchar, nchar
      AND c.user_type_id = c.system_type_id
    GROUP BY tb.object_id
)
SELECT @union = STRING_AGG(CAST(
           N'SELECT CAST(N''' + REPLACE(tb.nm, N'''', N'''''') + N''' AS nvarchar(260)) AS object_name, '
         + N'CAST(' +
           CASE WHEN p.wh IS NULL
                THEN N'0'
                ELSE N'(SELECT COUNT(*) FROM ' + tb.fq + N' WHERE ' + p.wh + N')'
           END
         + N' AS bigint) AS rows_found' AS nvarchar(max)),
       N' UNION ALL ')
FROM tbl AS tb
LEFT JOIN pred AS p ON p.object_id = tb.object_id;

DECLARE @sql nvarchar(max) =
    N'SELECT object_name, rows_found FROM (' + @union + N') AS r ORDER BY object_name;';

EXEC sp_executesql
    @sql,
    N'@p1 nvarchar(200), @p2 nvarchar(200), @p3 nvarchar(200)',
    @p1 = @p1, @p2 = @p2, @p3 = @p3;
