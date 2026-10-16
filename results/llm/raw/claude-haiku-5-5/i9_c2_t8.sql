SET NOCOUNT ON;

DECLARE @v1 nvarchar(200) = N'Subject_0000042';
DECLARE @v2 nvarchar(200) = N'subject42@example.invalid';
DECLARE @v3 nvarchar(200) = N'+1-555-0000042';

-- One row per base table, with a predicate over its character columns (NULL if none)
CREATE TABLE #targets (
    rn      int IDENTITY(1,1) NOT NULL,
    obj     nvarchar(300) NOT NULL,
    qobj    nvarchar(400) NOT NULL,
    pred    nvarchar(max) NULL
);

INSERT INTO #targets (obj, qobj, pred)
SELECT
    CAST(t.TABLE_SCHEMA + N'.' + t.TABLE_NAME AS nvarchar(300)),
    CAST(QUOTENAME(t.TABLE_SCHEMA) + N'.' + QUOTENAME(t.TABLE_NAME) AS nvarchar(400)),
    STRING_AGG(
        CAST(QUOTENAME(c.COLUMN_NAME) + N' IN (@v1, @v2, @v3)' AS nvarchar(max)),
        N' OR '
    ) WITHIN GROUP (ORDER BY c.COLUMN_NAME)
FROM INFORMATION_SCHEMA.TABLES AS t
LEFT JOIN INFORMATION_SCHEMA.COLUMNS AS c
    ON  c.TABLE_SCHEMA = t.TABLE_SCHEMA
    AND c.TABLE_NAME   = t.TABLE_NAME
    AND c.DATA_TYPE IN (N'char', N'nchar', N'varchar', N'nvarchar')
WHERE t.TABLE_TYPE = N'BASE TABLE'
GROUP BY t.TABLE_SCHEMA, t.TABLE_NAME;

CREATE TABLE #results (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @i    int = 1;
DECLARE @max  int = (SELECT MAX(rn) FROM #targets);
DECLARE @obj  nvarchar(300);
DECLARE @qobj nvarchar(400);
DECLARE @pred nvarchar(max);
DECLARE @sql  nvarchar(max);
DECLARE @cnt  bigint;

WHILE @i <= ISNULL(@max, 0)
BEGIN
    SELECT @obj = obj, @qobj = qobj, @pred = pred
    FROM #targets
    WHERE rn = @i;

    SET @cnt = 0;

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @c = COUNT_BIG(*) FROM ' + @qobj
                 + N' WHERE ' + @pred + N';';

        EXEC sys.sp_executesql
            @sql,
            N'@c bigint OUTPUT, @v1 nvarchar(200), @v2 nvarchar(200), @v3 nvarchar(200)',
            @c  = @cnt OUTPUT,
            @v1 = @v1,
            @v2 = @v2,
            @v3 = @v3;
    END

    INSERT INTO #results (object_name, rows_found) VALUES (@obj, @cnt);

    SET @i += 1;
END

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;
