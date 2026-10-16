SET NOCOUNT ON;

DECLARE @sql nvarchar(max);

SELECT @sql = STUFF((
    SELECT N' UNION ALL SELECT N''' + REPLACE(s.name + N'.' + t.name, '''', '''''') + N''' AS object_name, COUNT(*) AS rows_found FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N' WHERE ' + ISNULL((
        SELECT NULLIF(
            STUFF((
                SELECT N' OR ' +
                    CASE 
                        WHEN ty.name IN (N'tinyint', N'smallint', N'int', N'bigint', N'decimal', N'numeric', N'money', N'smallmoney', N'float', N'real') 
                            THEN QUOTENAME(c.name) + N' = 42'
                        WHEN ty.name IN (N'varchar', N'nvarchar', N'char', N'nchar') 
                            THEN QUOTENAME(c.name) + N' IN (N''Subject_0000042'', N''subject42@example.invalid'', N''+1-555-0000042'')'
                        WHEN ty.name IN (N'text', N'ntext') 
                            THEN N'CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) IN (N''Subject_0000042'', N''subject42@example.invalid'', N''+1-555-0000042'')'
                    END
                FROM sys.columns c
                JOIN sys.types ty 
                    ON c.system_type_id = ty.system_type_id 
                    AND ty.user_type_id = ty.system_type_id
                WHERE c.object_id = t.object_id
                  AND ty.name IN (
                      N'tinyint', N'smallint', N'int', N'bigint', N'decimal', N'numeric', N'money', N'smallmoney', N'float', N'real',
                      N'varchar', N'nvarchar', N'char', N'nchar', N'text', N'ntext'
                  )
                FOR XML PATH(''), TYPE
            ).value(N'.', N'nvarchar(max)'), 1, 4, N'')
        ), N'')
    ), N'1=0')
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name
    FOR XML PATH(''), TYPE
).value(N'.', N'nvarchar(max)'), 1, 11, N'');

IF @sql <> N''
    EXEC(@sql);
ELSE
    SELECT CAST(NULL AS nvarchar(256)) AS object_name, 0 AS rows_found WHERE 1 = 0;
