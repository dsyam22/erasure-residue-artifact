/* Read-only verification: search entire database for the subject's original personal data. */
SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found bigint);

DECLARE @schema sysname, @table sysname, @sql nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @where nvarchar(max) = N'';

    SELECT @where = @where + N' OR '
        + QUOTENAME(c.name) + N' = @p_' + CAST(c.column_id AS nvarchar(10))
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND c.system_type_id IN (167, 175, 231, 239, 241, 99) /* char/varchar/nchar/nvarchar/ntext/xml */
      AND c.is_computed = 0;

    IF @where <> N''
    BEGIN
        SET @where = N' WHERE ' + STUFF(@where, 1, 4, N'');

        DECLARE @params nvarchar(max) = N'@p_id int, @p_name nvarchar(200), @p_email nvarchar(320), @p_phone nvarchar(50)';

        SET @sql = N'SELECT @cnt = COUNT(*) FROM '
            + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
            + @where;

        DECLARE @cnt bigint = 0;

        BEGIN TRY
            EXEC sp_executesql
                @sql,
                @params + N', @cnt bigint OUTPUT',
                @p_id = @customer_id,
                @p_name = @full_name,
                @p_email = @email,
                @p_phone = @phone,
                @cnt = @cnt OUTPUT;
        END TRY
        BEGIN CATCH
            SET @cnt = 0;
        END CATCH

        INSERT INTO @results (object_name, rows_found)
        VALUES (@schema + N'.' + @table, @cnt);
    END

    FETCH NEXT FROM cur INTO @schema, @table;
END

CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
