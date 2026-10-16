SET NOCOUNT ON;

DECLARE @v1 nvarchar(200) = N'Subject_0000042';
DECLARE @v2 nvarchar(200) = N'subject42@example.invalid';
DECLARE @v3 nvarchar(200) = N'+1-555-0000042';
DECLARE @v4 nvarchar(200) = N'42';

CREATE TABLE #results (
    object_name nvarchar(260) NOT NULL,
    rows_found  int           NOT NULL
);

-- Explicitly checked: dbo.customer (exact key/value match)
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email     = N'subject42@example.invalid'
   OR phone     = N'+1-555-0000042';

-- Explicitly checked: reporting.customer_replica (exact key/value match)
INSERT INTO #results (object_name, rows_found)
SELECT N'reporting.customer_replica',
       COUNT(*)
FROM reporting.customer_replica
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email     = N'subject42@example.invalid'
   OR phone     = N'+1-555-0000042';

-- Scan all other user base tables for the original personal data
-- in character columns (case-insensitive substring match).
DECLARE @s sysname, @t sysname, @pred nvarchar(max), @sql nvarchar(max), @c int;

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.TABLE_SCHEMA, t.TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES AS t
    WHERE t.TABLE_TYPE = 'BASE TABLE'
      AND NOT (t.TABLE_SCHEMA = 'dbo'       AND t.TABLE_NAME = 'customer')
      AND NOT (t.TABLE_SCHEMA = 'reporting' AND t.TABLE_NAME = 'customer_replica')
    ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME;

OPEN tcur;
FETCH NEXT FROM tcur INTO @s, @t;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @c = 0;

    SELECT @pred = STRING_AGG(q.x, N' OR ')
    FROM (
        SELECT
            N'(CHARINDEX(@v1, ' + QUOTENAME(c.COLUMN_NAME) + N') > 0 OR '
          + N'CHARINDEX(@v2, ' + QUOTENAME(c.COLUMN_NAME) + N') > 0 OR '
          + N'CHARINDEX(@v3, ' + QUOTENAME(c.COLUMN_NAME) + N') > 0)' AS x
        FROM INFORMATION_SCHEMA.COLUMNS AS c
        WHERE c.TABLE_SCHEMA = @s
          AND c.TABLE_NAME   = @t
          AND c.DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar')
    ) AS q;

    IF @pred IS NULL
    BEGIN
        INSERT INTO #results (object_name, rows_found)
        VALUES (QUOTENAME(@s) + N'.' + QUOTENAME(@t), 0);
    END
    ELSE
    BEGIN
        SET @sql = N'SELECT @c = COUNT(*) FROM '
                 + QUOTENAME(@s) + N'.' + QUOTENAME(@t)
                 + N' WHERE ' + @pred + N';';

        EXEC sp_executesql
            @sql,
            N'@v1 nvarchar(200), @v2 nvarchar(200), @v3 nvarchar(200), @c int OUTPUT',
            @v1 = @v1, @v2 = @v2, @v3 = @v3, @c = @c OUTPUT;

        INSERT INTO #results (object_name, rows_found)
        VALUES (QUOTENAME(@s) + N'.' + QUOTENAME(@t), @c);
    END

    FETCH NEXT FROM tcur INTO @s, @t;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
