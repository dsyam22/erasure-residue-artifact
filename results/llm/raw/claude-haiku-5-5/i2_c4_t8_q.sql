-- Read-only reconnaissance: where could erased personal data for customer_id 42 still live?

-- 1. All user tables with temporal (system-versioned) and CDC status
SELECT  s.name           AS schema_name,
        t.name           AS table_name,
        t.temporal_type_desc,
        hs.name          AS history_schema,
        ht.name          AS history_table,
        t.is_tracked_by_cdc,
        t.is_memory_optimized,
        t.is_ms_shipped
FROM    sys.tables t
JOIN    sys.schemas s  ON s.schema_id = t.schema_id
LEFT JOIN sys.tables ht ON ht.object_id = t.history_table_id
LEFT JOIN sys.schemas hs ON hs.schema_id = ht.schema_id
WHERE   t.is_ms_shipped = 0
ORDER BY schema_name, table_name;

-- 2. Columns that could hold identifiers or personal data:
--    all character/XML/binary columns, plus any column whose name hints at personal data
SELECT  s.name AS schema_name,
        t.name AS table_name,
        c.name AS column_name,
        ty.name AS type_name,
        c.max_length,
        c.is_nullable
FROM    sys.columns c
JOIN    sys.tables  t  ON t.object_id = c.object_id
JOIN    sys.schemas s  ON s.schema_id = t.schema_id
JOIN    sys.types   ty ON ty.user_type_id = c.user_type_id
WHERE   t.is_ms_shipped = 0
  AND ( ty.name IN ('char','varchar','nchar','nvarchar','text','ntext','xml','sysname','varbinary','image')
     OR c.name LIKE '%cust%' OR c.name LIKE '%name%' OR c.name LIKE '%mail%'
     OR c.name LIKE '%phone%' OR c.name LIKE '%subj%' OR c.name LIKE '%person%'
     OR c.name LIKE '%user%' OR c.name LIKE '%contact%' OR c.name LIKE '%addr%' )
ORDER BY schema_name, table_name, c.column_id;

-- 3. Row counts per table (heap or clustered index), to spot where data remains
SELECT  OBJECT_SCHEMA_NAME(p.object_id) AS schema_name,
        OBJECT_NAME(p.object_id)        AS table_name,
        SUM(p.rows)                     AS row_count
FROM    sys.partitions p
JOIN    sys.tables t ON t.object_id = p.object_id
WHERE   p.index_id IN (0, 1)
  AND   t.is_ms_shipped = 0
GROUP BY p.object_id
ORDER BY schema_name, table_name;

-- 4. Foreign keys that reference dbo.customer (child tables may hold copies of customer_id)
SELECT  fk.name AS fk_name,
        OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
        OBJECT_NAME(fk.parent_object_id)        AS child_table,
        OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
        OBJECT_NAME(fk.referenced_object_id)        AS parent_table,
        fk.delete_referential_action_desc
FROM    sys.foreign_keys fk
WHERE   fk.referenced_object_id = OBJECT_ID(N'dbo.customer')
   OR   fk.parent_object_id     = OBJECT_ID(N'dbo.customer');

-- 5. Triggers on any user table (may copy data into audit/log tables)
SELECT  OBJECT_SCHEMA_NAME(tr.parent_id) AS schema_name,
        OBJECT_NAME(tr.parent_id)        AS table_name,
        tr.name                          AS trigger_name,
        tr.is_disabled,
        OBJECT_DEFINITION(tr.object_id)  AS trigger_definition
FROM    sys.triggers tr
WHERE   tr.is_ms_shipped = 0;

-- 6. Views and procedures whose definitions mention customer or personal-data terms
SELECT  OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,
        OBJECT_NAME(m.object_id)        AS object_name,
        o.type_desc
FROM    sys.sql_modules m
JOIN    sys.objects o ON o.object_id = m.object_id
WHERE   m.definition LIKE '%customer%'
   OR   m.definition LIKE '%email%'
   OR   m.definition LIKE '%phone%'
ORDER BY schema_name, object_name;
