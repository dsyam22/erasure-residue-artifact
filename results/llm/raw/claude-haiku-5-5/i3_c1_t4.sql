SET NOCOUNT ON;

-- Original personal data of the erased data subject (customer_id 42 / member_id 42)
CREATE TABLE #targets (val nvarchar(200) NOT NULL);
INSERT INTO #targets (val) VALUES
    (N'Subject_0000042'),
    (N'subject42@example.invalid'),
    (N'+1-555-0000042');

CREATE TABLE #results (
    object_name nvarchar(260) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @object_id int;
DECLARE @pred nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT SCHEMA_NAME(t.schema_id), t.name, t.object_id
    FROM sys.tables AS t
    WHERE t.is_ms_shipped = 0
    ORDER BY 1, 2;

OPEN tbl;
FETCH NEXT FROM tbl INTO @schema, @table, @object_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Build predicate over all character columns of this table
    SET @pred = NULL;
    SELECT @pred = STRING_AGG(
                       CAST(QUOTENAME(c.name) + N' IN (SELECT val FROM #targets)' AS nvarchar(max)),
                       N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = @object_id
      AND c.system_type_id IN (167, 175, 231, 239); -- varchar, char, nvarchar, nchar

    SET @cnt = 0;
    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @c = COUNT_BIG(*) FROM '
                 + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';
        EXEC sp_executesql @sql, N'@c bigint OUTPUT', @c = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (CAST(@schema + N'.' + @table AS nvarchar(260)), @cnt);

    FETCH NEXT FROM tbl INTO @schema, @table, @object_id;
END

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
DROP TABLE #targets;
