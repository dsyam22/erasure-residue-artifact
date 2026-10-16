SET NOCOUNT ON;

CREATE TABLE #r (
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @sql nvarchar(max) = N'';

SELECT @sql += N'INSERT INTO #r (object_name, rows_found) SELECT N'''
    + REPLACE(s.name + N'.' + t.name, N'''', N'''''')
    + N''', COUNT(*) FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
    + N' WHERE '
    + ISNULL((
        SELECT STRING_AGG(CAST(
            N'(' + QUOTENAME(c.name) + N' LIKE N''%555-0000042%'''
          + N' OR ' + QUOTENAME(c.name) + N' LIKE N''%5550000042%'')'
          AS nvarchar(max)), N' OR ')
        FROM sys.columns c
        JOIN sys.types ty ON ty.user_type_id = c.user_type_id
        WHERE c.object_id = t.object_id
          AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar')
      ), N'1=0')
    + N';' + NCHAR(10)
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id;

EXEC sys.sp_executesql @sql;

SELECT object_name, rows_found
FROM #r
ORDER BY object_name;

DROP TABLE #r;
