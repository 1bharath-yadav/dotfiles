---
id: Integrity-Constraints
aliases: []
tags:
  - anki
  - study
subject: Database-Warehousing
title: Integrity Constraints
topic: Integrity-Constraints
---

## Intigrity constraints:(Maintain the accuracy and consistency of data in the database)

### On single relation:

- Not null : Ensures that a column cannot have a NULL value.
- Unique : Ensures that all values in a column are unique.
- Primary key : Uniquely identifies each record in a table.
- check : Ensures that all values in a column satisfy a specific condition. check(P) where P is predicate on the attributes of the relation.

### Referential Intigrity:

- Ensures that a foreign key value in one table matches a primary key value in another table. It maintains the consistency of data across related tables.
- Foreign key : A foreign key is a column or a set of columns in one table that refers to the primary key in another table. It establishes a link between the two tables and enforces referential integrity.

- Cascading actions : When a foreign key is defined with cascading actions, it specifies what should happen to the related records in the child table when a record in the parent table is updated or deleted. The common cascading actions are:
  - ON DELETE CASCADE : If a record in the parent table is deleted, all related records in the child table will also be deleted.
  - ON UPDATE CASCADE : If a record in the parent table is updated, all related records in the child table will also be updated.
  - Alternative actions include SET NULL, SET DEFAULT, and RESTRICT, which define different behaviors for handling updates and deletions in the parent table.

## Intigrity constrain violations during transactions:

- How to insert a tuple without causeing a violation of the intigrity constraints:
  - lets say mother and father attributes has null constraint so we cant insert a tuple with null values in these attributes. So we can insert a tuple with mother and father attributes as null and then update the tuple with the correct values for mother and father attributes.
  - Defer constraint checking: Some database systems allow you to defer the checking of certain constraints until the end of a transaction. This means that you can temporarily violate a constraint during the transaction, as long as the constraint is satisfied by the time the transaction is committed. This can be useful in scenarios where you need to perform multiple operations that may temporarily violate constraints, but ultimately result in a valid state.
