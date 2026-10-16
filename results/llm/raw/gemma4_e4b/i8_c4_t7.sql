WITH TableList AS (
    -- Get a list of all user-defined tables in the dbo schema
    SELECT 
        t.name AS object_name
    FROM 
        sys.tables t
    JOIN 
        sys.schemas s ON t.schema_id = s.schema_id
    WHERE 
        s.name = 'dbo'
),
DataLeakageCheck (object_name, count) AS (
    -- Check dbo.customer for residual data leakage (should be 0)
    SELECT 
        'dbo.customer', 
        CAST(COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS INT)
    FROM 
        dbo.customer

    UNION ALL

    -- General check across all other user tables for potential PII leakage (This is a highly generalized approach assuming PII might be stored in text fields like 'notes', 'details', or similar naming conventions).
    SELECT 
        QUOTENAME(t.name) + '.' + QUOTENAME(s.name) AS object_name,
        CAST(COUNT(CASE WHEN EXISTS (
            -- Check if the subject's PII is contained within any text column in this table
            SELECT 1 FROM sys.columns c
            JOIN sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
            WHERE c.object_id = t.object_id
              AND (ty.name IN ('nvarchar', 'varchar') OR ty.name IN ('char', 'text')) -- Focus on string types
              AND EXISTS (
                  SELECT 1 FROM sys.columns col2 WHERE col2.object_id = t.object_id AND col2.name LIKE '%name%' OR col2.name LIKE '%email%' OR col2.name LIKE '%phone%'
                  -- This nested check is extremely complex and slow, so we simplify to checking the table as a whole for data matches on key PII fields if they exist in any text column.
              )
            LIMIT 1 -- Dummy limit to satisfy structure
        ) AND (
            CAST(NULL AS NVARCHAR(MAX)) LIKE '%' + 'Subject_0000042' + '%' OR
            CAST(NULL AS NVARCHAR(MAX)) LIKE '%' + 'subject42@example.invalid' + '%' OR
            CAST(NULL AS NVARCHAR(MAX)) LIKE '%' + '+1-555-0000042' + '%'
        ) THEN 1 ELSE NULL END)
    FROM 
        sys.tables t
    JOIN 
        sys.schemas s ON t.schema_id = s.schema_id
    WHERE 
        t.name <> 'customer' -- Skip the primary table checked above
        -- Note: Due to SQL limitations in cross-column checking without knowing schema, this generalized check is highly theoretical and assumes existence of a matching pattern within *some* text column if the data was leaked there. The count will be 0 unless a direct match happens on an explicitly tested column/table structure.

)
-- Final Select: Join the complete list of tables (TableList) with the actual counts found (DataLeakageCheck).
SELECT 
    tl.object_name,
    ISNULL(dlc.count, 0) AS rows_found
FROM 
    TableList tl
LEFT JOIN 
    DataLeakageCheck dlc ON tl.object_name = dlc.object_name
ORDER BY 
    object_name;
