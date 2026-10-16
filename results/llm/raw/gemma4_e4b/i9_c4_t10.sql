WITH CheckedObjects AS (
    -- Checking dbo.customer for any residual data matching the subject's identifiers.
    SELECT 
        'dbo.customer' AS object_name, 
        COUNT(*) AS rows_found
    FROM 
        dbo.customer
    WHERE 
        full_name = 'Subject_0000042' OR 
        email = 'subject42@example.invalid' OR 
        phone = '+1-555-0000042'
)
-- Union all results to ensure the structure is maintained, even if only one object is checked.
SELECT object_name, rows_found FROM CheckedObjects;
