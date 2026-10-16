DECLARE @name  nvarchar(200) = N'Subject_0000042',
        @email nvarchar(200) = N'subject42@example.invalid',
        @phone nvarchar(200) = N'+1-555-0000042';

DECLARE @sql nvarchar(max);

;WITH colpred AS (
    SELECT c.object_id,
           p = N'CHARINDEX(@name, ' + QUOTENAME(c.name) + N') > 0 OR '
             + N'CHARINDEX(@email, ' + QUOTENAME(c.name) + N') > 0 OR '
             + N'CHARINDEX(@phone, ' + QUOTENAME(c.name) + N') > 0'
    FROM sys.columns AS c
    JOIN sys.types AS ty
      ON ty.user_type_id = c.user_type_id
    WHERE ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar')
),
tblpred AS (
    SELECT object_id,
           p = STRING_AGG(CAST(p AS nvarchar(max)), N' OR ')
    FROM colpred
    GROUP BY object_id
)
SELECT @sql = STRING_AGG(CAST(x.stmt AS nvarchar(max)), N' UNION ALL ')
              WITHIN GROUP (ORDER BY x.obj)
FROM (
    SELECT t.object_id AS obj,
           stmt = N'SELECT N'''
                + REPLACE(SCHEMA_NAME(t.schema_id) + N'.' + t.name, N'''', N'''''')
                + N''' AS object_name, COUNT(*) AS rows_found FROM '
                + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name)
                + N' WHERE ' + ISNULL(tp.p, N'1 = 0')
    FROM sys.tables AS t
    LEFT JOIN tblpred AS tp
      ON tp.object_id = t.object_id
    WHERE t.is_ms_shipped = 0
) AS x;

EXEC sys.sp_executesql
     @sql,
     N'@name nvarchar(200), @email nvarchar(200), @phone nvarchar(200)',
     @name = @name,
     @email = @email,
     @phone = @phone;
