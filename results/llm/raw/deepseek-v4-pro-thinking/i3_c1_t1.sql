SET NOCOUNT ON;

DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';
DECLARE @customer_id int = 42;
DECLARE @member_id int = 42;

CREATE TABLE #results (
    object_name nvarchar(500) NOT NULL,
    rows_found bigint NOT NULL
);

INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member', COUNT_BIG(*)
FROM dbo.member
WHERE member_id = @member_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

DECLARE @history_name nvarchar(500);
DECLARE @history_quoted nvarchar(500);

SELECT @history_name = s.name + N'.' + h.name,
       @history_quoted = QUOTENAME(s.name) + N'.' + QUOTENAME(h.name)
FROM sys.tables AS t
JOIN sys.tables AS h
    ON t.history_table_id = h.object_id
   AND h.temporal_type = 1
JOIN sys.schemas AS s
    ON h.schema_id = s.schema_id
WHERE t.object_id = OBJECT_ID(N'dbo.member')
  AND t.temporal_type = 2;

IF @history_name IS NOT NULL
BEGIN
    DECLARE @sql nvarchar(max);
    DECLARE @cnt bigint;

    SET @sql = N'SELECT @cnt = COUNT_BIG(*)
                 FROM ' + @history_quoted + N'
                 WHERE member_id = @member_id
                    OR full_name = @full_name
                    OR email = @email
                    OR phone = @phone;';

    EXEC sp_executesql @sql,
         N'@member_id int, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(50), @cnt bigint OUTPUT',
         @member_id = @member_id,
         @full_name = @full_name,
         @email = @email,
         @phone = @phone,
         @cnt = @cnt OUTPUT;

    INSERT INTO #results (object_name, rows_found)
    VALUES (@history_name, @cnt);
END;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;
