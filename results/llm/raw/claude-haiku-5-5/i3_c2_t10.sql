SET NOCOUNT ON;

-- Original personal data of the erased subject (customer_id 42 / member_id 42)
DECLARE @fn nvarchar(200) = N'Subject_0000042';
DECLARE @em nvarchar(200) = N'subject42@example.invalid';
DECLARE @ph nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results
(
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

-- Every user table (including CDC change tables and temporal history tables)
-- that has a full_name, email, or phone column is checked.
DECLARE @s sysname, @t sysname, @pred nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name,
           t.name,
           STRING_AGG(CAST(QUOTENAME(c.name) + N' = ' +
                           CASE c.name
                               WHEN N'full_name' THEN N'@fn'
                               WHEN N'email'     THEN N'@em'
                               ELSE N'@ph'
                           END AS nvarchar(max)), N' OR ')
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    JOIN sys.columns AS c ON c.object_id = t.object_id
    WHERE c.name IN (N'full_name', N'email', N'phone')
      AND t.is_ms_shipped = 0
    GROUP BY s.name, t.name;

OPEN tbl;
FETCH NEXT FROM tbl INTO @s, @t, @pred;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cnt = 0;
    SET @sql = N'SELECT @cnt_out = COUNT_BIG(*) FROM '
             + QUOTENAME(@s) + N'.' + QUOTENAME(@t)
             + N' WHERE ' + @pred + N';';

    EXEC sys.sp_executesql
         @sql,
         N'@fn nvarchar(200), @em nvarchar(200), @ph nvarchar(200), @cnt_out bigint OUTPUT',
         @fn = @fn, @em = @em, @ph = @ph, @cnt_out = @cnt OUTPUT;

    INSERT INTO #results (object_name, rows_found)
    VALUES (CAST(@s AS nvarchar(128)) + N'.' + CAST(@t AS nvarchar(128)), ISNULL(@cnt, 0));

    FETCH NEXT FROM tbl INTO @s, @t, @pred;
END;

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
