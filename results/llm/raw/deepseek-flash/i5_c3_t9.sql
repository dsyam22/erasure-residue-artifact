/* Read-only verification script: checks whether the erased subject's original personal data
   still exists anywhere in the database (base table, temporal history, CDC, change tracking).
   Returns exactly one result set: object_name, rows_found. */

SET NOCOUNT ON;

DECLARE @cid        int           = 42;
DECLARE @full_name  nvarchar(200) = N'Subject_0000042';
DECLARE @email      nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone      nvarchar(200) = N'+1-555-0000042';

/* Collect every candidate object (in scope) that could hold this data.
   We include all user tables plus any CDC / change-tracking / temporal history
   objects, regardless of name, so nothing is missed. */
DECLARE @candidates TABLE (object_name sysname PRIMARY KEY);

INSERT INTO @candidates (object_name)
SELECT s.name + N'.' + t.name
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id;

/* CDC change tables (if any), even though cdc_enabled=0 for the db. */
INSERT INTO @candidates (object_name)
SELECT s.name + N'.' + t.name
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE s.name = N'cdc'
  AND NOT EXISTS (SELECT 1 FROM @candidates c WHERE c.object_name = s.name + N'.' + t.name);

/* Change-tracking side tables. */
INSERT INTO @candidates (object_name)
SELECT s.name + N'.' + t.name
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE (t.name LIKE N'%change_tracking%' OR s.name = N'changetracking')
  AND NOT EXISTS (SELECT 1 FROM @candidates c WHERE c.object_name = s.name + N'.' + t.name);

/* Now, for each candidate object, find the nvarchar/char columns that could
   contain the personal data, and count matching rows. Dynamic SQL builds one
   query per object, counting rows where any textual column matches any of the
   subject's identifiers. */
DECLARE @results TABLE (object_name sysname, rows_found bigint);

DECLARE @obj sysname;
DECLARE obj_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT object_name FROM @candidates;

OPEN obj_cursor;
FETCH NEXT FROM obj_cursor INTO @obj;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @schema sysname, @table sysname;
    SET @schema = PARSENAME(@obj, 2);
    SET @table  = PARSENAME(@obj, 1);

    /* Build the OR predicate across all text columns. */
    DECLARE @pred nvarchar(max) = N'';
    DECLARE @col sysname;

    DECLARE col_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT c.name
        FROM sys.columns AS c
        JOIN sys.types  AS ty ON ty.user_type_id = c.user_type_id
        WHERE c.object_id = OBJECT_ID(@obj)
          AND ty.name IN (N'nvarchar', N'nchar', N'varchar', N'char', N'text', N'ntext');

    OPEN col_cursor;
    FETCH NEXT FROM col_cursor INTO @col;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @pred = @pred
            + CASE WHEN @pred = N'' THEN N'' ELSE N' OR ' END
            + N'CONVERT(nvarchar(max), [' + @col + N']) IN (@full_name, @email, @phone)';
        FETCH NEXT FROM col_cursor INTO @col;
    END
    CLOSE col_cursor;
    DEALLOCATE col_cursor;

    IF @pred = N''
    BEGIN
        INSERT INTO @results (object_name, rows_found) VALUES (@obj, 0);
    END
    ELSE
    BEGIN
        DECLARE @sql nvarchar(max) =
            N'SELECT @cnt = COUNT_BIG(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
            + N' WHERE ' + @pred + N';';

        DECLARE @cnt bigint = 0;

        EXEC sp_executesql
            @sql,
            N'@full_name nvarchar(200), @email nvarchar(200), @phone nvarchar(200), @cnt bigint OUTPUT',
            @full_name = @full_name,
            @email     = @email,
            @phone     = @phone,
            @cnt       = @cnt OUTPUT;

        INSERT INTO @results (object_name, rows_found) VALUES (@obj, @cnt);
    END

    FETCH NEXT FROM obj_cursor INTO @obj;
END

CLOSE obj_cursor;
DEALLOCATE obj_cursor;

/* Single result set. */
SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
