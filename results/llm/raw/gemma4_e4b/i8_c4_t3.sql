WITH ObjectList AS (
    -- List every user-defined table we need to explicitly check. 
    -- Based on the provided schema, only dbo.customer exists.
    SELECT 'dbo.customer' AS object_name
),
SearchMatches AS (
    -- Perform the search across all relevant tables listed in ObjectList
    SELECT
        T.object_name,
        COUNT(1) AS RowsFound
    FROM 
        ObjectList T
    LEFT JOIN (
        SELECT 
            'dbo.customer' AS object_name,
            COUNT(*) AS RowCount
        FROM 
            dbo.customer
        WHERE 
            full_name = 'Subject_0000042' OR -- Check by full name
            email = 'subject42@example.invalid' OR -- Check by email
            phone = '+1-555-0000042' OR -- Check by phone
            CAST(customer_id AS NVARCHAR) LIKE '%42%' -- Safety check on customer ID field presence
        GROUP BY 1
    ) AS Matches ON T.object_name = Matches.object_name
    GROUP BY T.object_name, Matches.RowCount
)
-- Select the final required result set structure.
SELECT
    object_name,
    COALESCE(RowsFound, 0) AS rows_found
FROM SearchMatches;
