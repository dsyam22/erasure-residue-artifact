/*
No script can satisfy all of these requirements as stated.

A SELECT against dbo.customer can verify that no matching live rows remain,
but cannot verify that the original personal data is absent everywhere in
llm_i8.

DELETE can leave original data in the transaction log and in deallocated or
not-yet-cleaned data pages. SQL Server 2022 provides no supported SELECT-only
interface that exhaustively searches those locations and returns counts of
remaining rows by schema.table. Those locations also do not themselves have
schema.table names.

Searching arbitrary additional tables requires discovering their columns and
executing generated SQL; metadata SELECT statements alone do not inspect their
contents.

A feasible verification scope is all queryable table rows, including any
history and CDC tables, with permission to execute dynamically generated,
read-only SELECT statements. Such a check would not certify physical erasure
from transaction logs, database pages, or backups.
*/
