-- SCRIPT
SET NOCOUNT ON;

DECLARE @p1 nvarchar(400) = N'%' + REPLACE(REPLACE(REPLACE(REPLACE(N'Subject_0000042', N'!', N'!!'), N'%', N'!%'), N'_', N'!_'), N'[', N'![') + N'%';
DECLARE @p2 nvarchar(400) = N'%' + REPLACE(REPLACE(REPLACE(REPLACE(N'subject42@example.invalid', N'!', N'!!'), N'%', N'!%'), N'_', N'!_'), N'[', N'![') + N'%';
DECLARE @p3 nvarchar(400) = N'%' + REPLACE(REPLACE(REPLACE(REPLACE(N'+1-555-0000042', N'!', N'!!'), N'%', N'!%'), N'_', N'!_'), N'[', N'![') + N'%';

CREATE TABLE #res (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @oid  int,
        @tbl  nvarchar(300),
        @raw  nvarchar(300),
        @pred nvarchar(max),
        @sql  nvarchar(max),
        @n    bigint;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id,
           QUOTENAME(s.name) + N'.' + QUOTENAME(t.name),
           s.name + N'.' + t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;

OPEN cur;
FETCH NEXT FROM cur INTO @oid, @tbl, @raw;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;

    -- Text-type columns: match any of the three original values
    SELECT @pred = STRING_AGG(
               N'(' + QUOTENAME(c.name) + N' LIKE @p1 ESCAPE ''!'' OR '
                    + QUOTENAME(c.name) + N' LIKE @p2 ESCAPE ''!'' OR '
                    + QUOTENAME(c.name) + N' LIKE @p3 ESCAPE ''!'')',
               N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = @oid
      AND c.system_type_id IN (167, 175, 231, 239);  -- varchar, char, nvarchar, nchar

    -- Subject's customer_id (42) in any table that carries it
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = @oid AND name = N'customer_id')
        SET @pred = ISNULL(@pred + N' OR ', N'') + N'(' + QUOTENAME(N'customer_id') + N' = 42)';

    SET @n = 0;

    IF @pred IS NULL
    BEGIN
        INSERT INTO #res (object_name, rows_found) VALUES (@raw, 0);
    END
    ELSE
    BEGIN
        SET @sql = N'SELECT @n_out = COUNT_BIG(*) FROM ' + @tbl + N' WHERE (' + @pred + N');';
        EXEC sp_executesql
             @sql,
             N'@p1 nvarchar(400), @p2 nvarchar(400), @p3 nvarchar(400), @n_out bigint OUTPUT',
             @p1 = @p1, @p2 = @p2, @p3 = @p3, @n_out = @n OUTPUT;

        INSERT INTO #res (object_name, rows_found) VALUES (@raw, ISNULL(@n, 0));
    END

    FETCH NEXT FROM cur INTO @oid, @tbl, @raw;
END

CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found
FROM #res
ORDER BY object_name;
