-- llm_truth.sql - ground truth and "full checklist" baseline.
-- sqlcmd variables: FIELD (email or phone), VALUE (the subject's original value)
-- Counts, in every table of the current database that has that column (source tables, CDC
-- change tables, temporal history tables, copies), the rows still holding the value.
-- Returns one result set: object_name, rows_found.
SET NOCOUNT ON;
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql = @sql + N'SELECT ''' + s.name + N'.' + t.name + N''' AS object_name, COUNT(*) AS rows_found FROM '
            + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N' WHERE ' + QUOTENAME(c.name) + N' = @v UNION ALL '
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE c.name = '$(FIELD)';
IF LEN(@sql) > 0
BEGIN
    SET @sql = LEFT(@sql, LEN(@sql) - 10);
    EXEC sp_executesql @sql, N'@v NVARCHAR(200)', @v = N'$(VALUE)';
END
ELSE
    SELECT 'none' AS object_name, 0 AS rows_found;
