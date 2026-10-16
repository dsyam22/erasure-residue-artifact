/* Read-only verification: search the whole database for the erased personal data. */
SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name   nvarchar(200) = N'Subject_0000042';
DECLARE @email       nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone       nvarchar(50)  = N'+1-555-0000042';

CREATE TABLE #results (
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @schema sysname, @table sysname, @sql nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'';

    /* Build a UNION of per-column predicates so any of the subject's
       original values matching in any text column is counted once per row. */
    SELECT @sql = @sql + N'
    SELECT @cnt = @cnt + COUNT(*)
    FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
    WHERE ' + QUOTENAME(c.name) + N' LIKE N''%'' + @v + N''%'';'
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND c.system_type_id IN (167, 231, 175, 239, 35, 99, 241)  -- char/varchar/nchar/nvarchar/text/ntext/xml
    ;

    IF @sql = N''
        INSERT INTO #results (object_name, rows_found)
        VALUES (@schema + N'.' + @table, 0);
    ELSE
    BEGIN
        /* Wrap so we can pass the four values as variables and count distinct rows. */
        DECLARE @count bigint = 0;

        DECLARE @blk nvarchar(max) = N'
        DECLARE @cnt bigint = 0;
        DECLARE @v nvarchar(400) = @full_name;
        ' + @sql + N'
        SET @v = @email;
        ' + @sql + N'
        SET @v = @phone;
        ' + @sql + N'
        SET @v = CAST(@customer_id AS nvarchar(20));
        ' + @sql + N'
        SELECT @out = @cnt;';

        EXEC sp_executesql @blk,
             N'@full_name nvarchar(200), @email nvarchar(320), @phone nvarchar(50), @customer_id int, @out bigint OUTPUT',
             @full_name, @email, @phone, @customer_id, @count OUTPUT;

        INSERT INTO #results (object_name, rows_found)
        VALUES (@schema + N'.' + @table, @count);
    END

    FETCH NEXT FROM cur INTO @schema, @table;
END

CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
