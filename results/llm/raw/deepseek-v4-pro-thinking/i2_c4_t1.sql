SET NOCOUNT ON;

CREATE TABLE #Results (
    object_name nvarchar(257) NOT NULL,
    rows_found bigint NOT NULL
);

DECLARE @SchemaName sysname;
DECLARE @TableName sysname;
DECLARE @ObjectID int;
DECLARE @ObjectNameQuoted nvarchar(257);
DECLARE @ObjectNamePlain nvarchar(257);
DECLARE @FullName nvarchar(100) = N'Subject_0000042';
DECLARE @Email nvarchar(100) = N'subject42@example.invalid';
DECLARE @Phone nvarchar(100) = N'+1-555-0000042';
DECLARE @CustomerID int = 42;
DECLARE @SQL nvarchar(max);
DECLARE @Conditions nvarchar(max);
DECLARE @Cnt bigint;

DECLARE tables_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name, t.name, t.object_id
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
  AND EXISTS (
      SELECT 1
      FROM sys.columns AS c
      WHERE c.object_id = t.object_id
        AND (
            (c.name = N'customer_id' AND c.system_type_id IN (48,52,56,127,106,108,122,60))
            OR (c.name IN (N'full_name', N'email', N'phone') AND c.system_type_id IN (167,175,231,239))
        )
  );

OPEN tables_cursor;
FETCH NEXT FROM tables_cursor INTO @SchemaName, @TableName, @ObjectID;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @ObjectNameQuoted = QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName);
    SET @ObjectNamePlain = @SchemaName + N'.' + @TableName;
    SET @Conditions = NULL;

    SELECT @Conditions = STRING_AGG(
        CASE
            WHEN c.name = N'customer_id' AND c.system_type_id IN (48,52,56,127,106,108,122,60)
                THEN N'(' + QUOTENAME(c.name) + N' = @P_CustomerID)'
            WHEN c.name = N'full_name' AND c.system_type_id IN (167,175,231,239)
                THEN N'(' + QUOTENAME(c.name) + N' = @P_FullName)'
            WHEN c.name = N'email' AND c.system_type_id IN (167,175,231,239)
                THEN N'(' + QUOTENAME(c.name) + N' = @P_Email)'
            WHEN c.name = N'phone' AND c.system_type_id IN (167,175,231,239)
                THEN N'(' + QUOTENAME(c.name) + N' = @P_Phone)'
        END,
        N' OR '
    ) WITHIN GROUP (ORDER BY c.column_id)
    FROM sys.columns AS c
    WHERE c.object_id = @ObjectID;

    IF @Conditions IS NULL
        SET @Cnt = 0;
    ELSE
    BEGIN
        SET @SQL = N'SELECT @Cnt = COUNT(*) FROM ' + @ObjectNameQuoted + N' WHERE ' + @Conditions + N';';
        EXEC sys.sp_executesql @SQL,
            N'@P_CustomerID int, @P_FullName nvarchar(100), @P_Email nvarchar(100), @P_Phone nvarchar(100), @Cnt bigint OUTPUT',
            @P_CustomerID = @CustomerID,
            @P_FullName = @FullName,
            @P_Email = @Email,
            @P_Phone = @Phone,
            @Cnt = @Cnt OUTPUT;
    END

    INSERT INTO #Results (object_name, rows_found)
    VALUES (@ObjectNamePlain, @Cnt);

    FETCH NEXT FROM tables_cursor INTO @SchemaName, @TableName, @ObjectID;
END

CLOSE tables_cursor;
DEALLOCATE tables_cursor;

SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;
