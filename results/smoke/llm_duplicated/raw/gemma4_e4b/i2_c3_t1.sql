WITH CheckResults AS (
    -- 1. Check the active/current state of the main temporal table
    SELECT 
        'dbo.customer' AS object_name, 
        COUNT(T.customer_id) AS rows_found
    FROM dbo.customer T
    WHERE T.customer_id = 42 
      AND T.full_name LIKE 'Subject\_0000042%'

    UNION ALL

    -- 2. Check the explicit history table (where deleted data resides)
    SELECT 
        'dbo.customer_history' AS object_name, 
        COUNT(T.customer_id) AS rows_found
    FROM dbo.customer_history T
    WHERE T.customer_id = 42 
      AND T.full_name LIKE 'Subject\_0000042%'

    /* 
       Note: Although the prompt suggested considering CDC, cdc_enabled=0, 
       and no other explicit tables were listed for data copies. 
       The temporal nature covers both current state and history storage.
    */
)
SELECT object_name, rows_found FROM CheckResults;
