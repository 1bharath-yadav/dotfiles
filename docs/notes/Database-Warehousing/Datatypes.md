---
id: Schemas
aliases: []
tags:
  - study
subject: Database-Warehousing
title: schemas
topic: schemas
---

## Built in datatypes in SQL:

- date : date values (YYYY-MM-DD)
- time : time values (HH:MM:SS)
- Timestamp : date and time values (YYYY-MM-DD HH:MM:SS)
- Interval : time interval values (e.g., 1 day, 2 hours)

## Index Creation:

- Indexes are used to improve the performance of database queries by allowing faster retrieval of data from tables.
- Indexes can be created on one or more columns of a table, and they can be of different types, such as B-tree, hash, or bitmap indexes.
- syntax to create an index:

```sql
CREATE INDEX index_name ON table_name (column1, column2, ...);
```

## User-defined datatypes in SQL:

- syntax:

```sql
create type Dollars as numeric (12,2) final
```

## Large Objects (LOBs):

- blob : binary large object, used to store large binary data such as images or audio files.
- clob : character large object, used to store large text data such as documents or XML

## Authorization:

### Forms of authorization on parts of the database:

◦ Read - allows reading, but not modification of data
◦ Insert - allows insertion of new data, but not modification of existing data
◦ Update - allows modification, but not deletion of data
◦ Delete - allows deletion of data

### Forms of authorization to modify the database schema

◦ Index - allows creation and deletion of indices
◦ Resources - allows creation of new relations
◦ Alteration - allows addition or deletion of attributes in a relation
◦ Drop - allows deletion of relations

syntax

```sql
grant <privilege list>
on <relation or view> to <user list>

--- All privileges can be granted to a user by using the keyword ALL instead of a list of privileges.

```

- replace grant with revoke to remove privileges from a user.
