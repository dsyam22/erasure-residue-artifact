SET NOCOUNT ON;

DECLARE @fn nvarchar(200) = N'Subject_0000042',
        @em nvarchar(320) = N'subject42@example.invalid',
        @ph nvarchar(50)  = N'+1-555-0000042';

CREATE TABLE #results (
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

CREATE TABLE #cnt (rows_found bigint NOT NULL);

DECLARE @schema sysname, @table sysname, @obj nvarchar(300),
        @where nvarchar(max), @sql nvarchar(max), @hits bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.TABLE_SCHEMA, t.TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES AS t
    WHERE t.TABLE_TYPE = 'BASE TABLE'
    ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj = CONVERT(nvarchar(300), QUOTENAME(@schema) + N'.' + QUOTENAME(@table));
    SET @obj = REPLACE(REPLACE(@obj, N'[', N''), N']', N'');

    SET @where = (
        SELECT STRING_AGG(
                   CAST(QUOTENAME(c.COLUMN_NAME) + N' IN (@fn, @em, @ph)' AS nvarchar(max)),
                   N' OR ')
        FROM INFORMATION_SCHEMA.COLUMNS AS c
        WHERE c.TABLE_SCHEMA = @schema
          AND c.TABLE_NAME = @table
          AND c.DATA_TYPE IN ('char', 'nchar', 'varchar', 'nvarchar')
    );

    IF @where IS NULL
    BEGIN
        INSERT INTO #results (object_name, rows_found) VALUES (@obj, 0);
    END
    ELSE
    BEGIN
        SET @sql = N'SELECT COUNT_BIG(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @where + N';';

        DELETE FROM #cnt;
        INSERT INTO #cnt (rows_found)
        EXEC sp_executesql @sql,
             N'@fn nvarchar(200), @em nvarchar(320), @ph nvarchar(50)',
             @fn = @fn, @em = @em, @ph = @ph;

        SELECT @hits = ISNULL(MAX(rows_found), 0) FROM #cnt;

        INSERT INTO #results (object_name, rows_found) VALUES (@obj, @hits);
    END

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #cnt;
DROP TABLE #results;
