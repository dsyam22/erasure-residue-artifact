-- SCRIPT
SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

DECLARE @results TABLE (
    object_name sysname,
    rows_found int
);

/* dbo.customer */
INSERT INTO @results (object_name, rows_found)
SELECT
    N'dbo.customer',
    COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* Add checks for any other tables/columns that could store the subject's
   original personal data.  The query below discovers candidate tables
   dynamically from the catalog and searches every character/binary column
   for the original values.  This keeps the script exhaustive without
   hard-coding every possible table. */

DECLARE @sql nvarchar(max) = N'';

SELECT @sql = STRING_AGG(
    CAST(
        N'INSERT INTO @results (object_name, rows_found)
          SELECT ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N', COUNT_BIG(*)
          FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N' AS src
          WHERE ' +
          STUFF((
              SELECT N' OR ' + QUOTENAME(c.name) + N' = @p'
              FROM sys.columns AS c
              JOIN sys.types AS ty
                ON ty.user_type_id = c.user_type_id
              WHERE c.object_id = t.object_id
                AND ty.system_type_id IN (167, 175, 231, 239, 165, 173)  -- varchar, char, nvarchar, nchar, varbinary, binary
              FOR XML PATH(''), TYPE
          ).value('.', 'nvarchar(max)'), 1, 4, N'') + N';'
        AS nvarchar(max)
    ),
    N''
)
FROM sys.tables AS t
JOIN sys.schemas AS s
  ON s.schema_id = t.schema_id
WHERE t.name <> N'customer'
   OR s.name <> N'dbo';

IF @sql IS NOT NULL AND LEN(@sql) > 0
BEGIN
    EXEC sp_executesql
        @sql,
        N'@p nvarchar(4000), @results TABLE (object_name sysname, rows_found int) READONLY',
        @p = @full_name,
        @results = @results;
END;

/* The dynamic block above only searched for the full_name value.  To also
   cover email and phone (and customer_id) across all candidate columns,
   run the same discovery for each remaining value. */

SET @sql = N'';

SELECT @sql = STRING_AGG(
    CAST(
        N'INSERT INTO @results (object_name, rows_found)
          SELECT ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N', COUNT_BIG(*)
          FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N' AS src
          WHERE ' +
          STUFF((
              SELECT N' OR ' + QUOTENAME(c.name) + N' = @p'
              FROM sys.columns AS c
              JOIN sys.types AS ty
                ON ty.user_type_id = c.user_type_id
              WHERE c.object_id = t.object_id
                AND ty.system_type_id IN (167, 175, 231, 239, 165, 173, 56, 127)  -- char/binary/numeric types
              FOR XML PATH(''), TYPE
          ).value('.', 'nvarchar(max)'), 1, 4, N'') + N';'
        AS nvarchar(max)
    ),
    N''
)
FROM sys.tables AS t
JOIN sys.schemas AS s
  ON s.schema_id = t.schema_id
WHERE t.name <> N'customer'
   OR s.name <> N'dbo';

IF @sql IS NOT NULL AND LEN(@sql) > 0
BEGIN
    EXEC sp_executesql
        @sql,
        N'@p nvarchar(4000), @results TABLE (object_name sysname, rows_found int) READONLY',
        @p = @email,
        @results = @results;

    EXEC sp_executesql
        @sql,
        N'@p nvarchar(4000), @results TABLE (object_name sysname, rows_found int) READONLY',
        @p = @phone,
        @results = @results;

    EXEC sp_executesql
        @sql,
        N'@p nvarchar(4000), @results TABLE (object_name sysname, rows_found int) READONLY',
        @p = CAST(@customer_id AS nvarchar(4000)),
        @results = @results;
END;

/* Collapse duplicate object rows (a table may match on multiple values). */
SELECT
    object_name,
    SUM(rows_found) AS rows_found
FROM @results
GROUP BY object_name
ORDER BY object_name;
