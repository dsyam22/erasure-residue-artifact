SET NOCOUNT ON;

DECLARE @p1 nvarchar(200) = N'Subject_0000042',
        @p2 nvarchar(200) = N'subject42@example.invalid',
        @p3 nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(400) NOT NULL PRIMARY KEY,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @col sysname,
        @pred nvarchar(max), @colpred nvarchar(max), @expr nvarchar(max),
        @sql nvarchar(max), @cnt bigint, @obj nvarchar(400);

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT TABLE_SCHEMA, TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = 'BASE TABLE'
    ORDER BY TABLE_SCHEMA, TABLE_NAME;

OPEN tbl;
FETCH NEXT FROM tbl INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = N'';
    SET @cnt = 0;

    DECLARE c CURSOR LOCAL FAST_FORWARD FOR
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = @schema
          AND TABLE_NAME = @table
          AND DATA_TYPE IN ('char','varchar','nchar','nvarchar','text','ntext')
        ORDER BY ORDINAL_POSITION;

    OPEN c;
    FETCH NEXT FROM c INTO @col;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @expr = N'CAST(' + QUOTENAME(@col) + N' AS nvarchar(max))';
        SET @colpred = N'(CHARINDEX(@p1, ' + @expr + N') > 0 OR CHARINDEX(@p2, ' + @expr
                     + N') > 0 OR CHARINDEX(@p3, ' + @expr + N') > 0)';

        IF @pred = N''
            SET @pred = @colpred;
        ELSE
            SET @pred = @pred + N' OR ' + @colpred;

        FETCH NEXT FROM c INTO @col;
    END

    CLOSE c;
    DEALLOCATE c;

    IF @pred <> N''
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';

        EXEC sp_executesql
            @sql,
            N'@p1 nvarchar(200), @p2 nvarchar(200), @p3 nvarchar(200), @cnt bigint OUTPUT',
            @p1 = @p1, @p2 = @p2, @p3 = @p3, @cnt = @cnt OUTPUT;
    END

    SET @obj = @schema + N'.' + @table;
    INSERT INTO #results (object_name, rows_found) VALUES (@obj, @cnt);

    FETCH NEXT FROM tbl INTO @schema, @table;
END

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
