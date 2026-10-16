SET NOCOUNT ON;

CREATE TABLE #residual_check
(
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @obj_name   nvarchar(300),
        @obj_quoted nvarchar(400),
        @cond       nvarchar(max),
        @sql        nvarchar(max),
        @n          bigint;

DECLARE obj_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT  s.name + N'.' + t.name,
            QUOTENAME(s.name) + N'.' + QUOTENAME(t.name),
            (
                SELECT STRING_AGG(CAST(
                    N'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(' + QUOTENAME(c.name) +
                    N',''+'',''''),''-'',''''),'' '',''''),''('',''''),'')'',''''')' +
                    N' LIKE ''%5550000042%''' AS nvarchar(max)), N' OR ')
                FROM sys.columns AS c
                WHERE c.object_id = t.object_id
                  AND c.system_type_id IN (167, 175, 231, 239)  -- varchar, char, nvarchar, nchar
            )
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN obj_cur;
FETCH NEXT FROM obj_cur INTO @obj_name, @obj_quoted, @cond;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @n = 0;

    IF @cond IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n_out = COUNT(*) FROM (SELECT 1 AS x FROM ' + @obj_quoted +
                   N' WHERE ' + @cond + N') AS m;';
        EXEC sys.sp_executesql @sql,
                               N'@n_out bigint OUTPUT',
                               @n_out = @n OUTPUT;
    END

    INSERT INTO #residual_check (object_name, rows_found)
    VALUES (@obj_name, @n);

    FETCH NEXT FROM obj_cur INTO @obj_name, @obj_quoted, @cond;
END

CLOSE obj_cur;
DEALLOCATE obj_cur;

SELECT object_name, rows_found
FROM #residual_check
ORDER BY object_name;

DROP TABLE #residual_check;
