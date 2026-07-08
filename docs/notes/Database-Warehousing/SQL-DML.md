---
id: SQL-DML
aliases: []
tags:
  - anki
  - study
subject: Database-Warehousing
title: SQL DML
topic: SQL-DML
---

<!--SR:!2026-06-30,1,230-->

Cartesian Product without JOIN #flashcard

- If multiple tables appear in FROM without WHERE/JOIN condition, SQL performs a Cartesian Product (CROSS JOIN).
- Number of output rows = (rows in first table) × (rows in second table).
- ⭐ Formula:
  $$
  |R \times S| = |R| \times |S|
  $$
- GATE Trap: Many students count only rows of one table and forget the implicit CROSS JOIN.
  ^^^

`EXCEPT ALL` subtracts occurrences, not just values. #flashcard

- If a value appears `m` times in the first query and `n` times in the second query, it appears `max(m−n,0)` times in the result.
- Here: Cartesian product gives each `eid` 4 copies.
- First `EXCEPT ALL`: `4−1=3` copies.
- Second `EXCEPT ALL`: `3−1=2` copies.
- Final rows = `7 employees × 2 copies = 14`.
  ^^^

Minimum salary of a department is not always excluded by the self-join. #flashcard

- `e1.salary > e2.salary` selects employees who have **at least one** employee with a lower salary.
- Only the **global minimum salary** (30000 here) has no lower salary, so it is excluded.
- `INTERSECT` returns only the distinct rows common to both queries.
- In this example, the result is:
  - (50000, D001)
  - (35000, D003)
  - (45000, D004)
    ^^^

WHERE vs HAVING #flashcard

- `WHERE` filters **rows before grouping**.
- `GROUP BY` creates groups.
- `HAVING` filters **groups after grouping**.
- ⭐ Execution order: `FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY`.
- GATE trap: Aggregate functions (e.g., `COUNT()`, `SUM()`) are **not allowed** in `WHERE` but **allowed** in `HAVING`.
  ^^^

To add column tame vendor (Both are valid):
ALTER TABLE vendor ADD COLUMN tame VARCHAR(255);
OR
ALTER TABLE vendor ADD tame VARCHAR(255);

This question is actually testing **SQL syntax**, but the answer key in the image is **incorrect** according to the SQL standard.

Let's examine each option.

### Option A ✅ **Correct SQL**

```sql
INSERT INTO Citizen (ID, profession, lastname, firstname)
VALUES (23, 'clerk', 'Holmes', 'Mark');
```

- Specifies the column names.
- Values match the columns.
- This is the recommended syntax.

---

### Option B ❌ Incorrect

```sql
INSERT INTO Citizen TABLE VALUES
(23,'clerk', 'Holmes', 'Mark');
```

Problems:

- `TABLE` should not be written here.
- Correct syntax is:

  ```sql
  INSERT INTO Citizen VALUES (...);
  ```

---

### Option C ✅ Correct **only if all columns are supplied in table order**

```sql
INSERT INTO Citizen
VALUES (23,'clerk','Holmes','Mark');
```

This is valid **provided**

- the table has exactly four columns, and
- the values are given in the same order as the table definition.

---

### Option D ❌ Incorrect

```sql
INSERT INTO Citizen
VALUES ('23','clerk','Holmes','Mark');
```

This depends on the DBMS.

- In **MySQL**, SQL Server, SQLite, etc., this usually works because `'23'` is implicitly converted to integer.
- In a **strict interpretation** (such as GATE DBMS), this is considered **incorrect** because `ID` is numeric and should not be written as a string literal.

---

## Final verdict

| Option | Correct?       | Reason                                    |
| ------ | -------------- | ----------------------------------------- |
| A      | ✅             | Standard SQL, specifies columns           |
| B      | ❌             | Invalid `TABLE` keyword                   |
| C      | ✅             | Valid if values follow table column order |
| D      | ❌ (GATE view) | Numeric value written as string literal   |

So **A and C should both be correct**.

If this question's official key marks **only C**, then the question is **poorly framed or the key is wrong**. GATE itself would normally accept **both A and C** unless the question explicitly stated that the column list is not allowed (which SQL does allow).

---

### #flashcard

**Valid SQL INSERT statement forms #flashcard**

- Two valid syntaxes:

  ```sql
  INSERT INTO table_name VALUES (...);
  ```

  ```sql
  INSERT INTO table_name(column1,column2,...)
  VALUES (...);
  ```

- The second form is safer because it does not depend on the table's column order.
- **GATE Trap:** `INSERT INTO table_name TABLE VALUES(...)` is invalid. Quoting numeric values may also be treated as incorrect in strict SQL questions.
  ^^^

- GROUP BY multiple columns #flashcard

GROUP BY A, B creates one group for each unique pair (A, B).
COUNT(\*) returns the number of rows in each group.
All non-aggregated columns in SELECT must appear in GROUP BY.

⭐ Formula:

- SELECT A, B, COUNT(\*)
- FROM T
- GROUP BY A, B;
- GATE Trap: GROUP BY A, B is not the same as GROUP BY A followed by GROUP BY B; it groups by the combination (A, B).
  ^^^

**When should `HAVING` be used?** #flashcard

- `HAVING` filters **groups**, not individual rows.
- It is used after `GROUP BY`.
- `WHERE` filters rows before grouping.
  ^^^

**How to find rows with the minimum value using `MIN()`?** #flashcard

- Compute the minimum in a subquery.
- Pattern:
  ```sql
  SELECT city
  FROM weatherReport
  WHERE rainfall = (
      SELECT MIN(rainfall)
      FROM weatherReport
  );
  ```
  ^^^

**How to find the minimum without using `MIN()`?** #flashcard

- A row is minimum if **no other row has a smaller value**.
- Pattern:
  ```sql
  SELECT key
  FROM T
  EXCEPT
  SELECT t1.key
  FROM T t1, T t2
  WHERE t1.value > t2.value;
  ```
  ^^^

**Self-join comparison trick (`t1.value < t2.value` vs `t1.value > t2.value`)** #flashcard

- `t1.value < t2.value` → rows smaller than at least one other row → **all except maximum**.
- `t1.value > t2.value` → rows greater than at least one other row → **all except minimum**.
- Using `EXCEPT` with the second pattern isolates the minimum row(s).
  ^^^

**`EXCEPT` operator** #flashcard

- Returns rows in the first query that are absent from the second.
- Removes duplicates automatically (set semantics).
- Pattern:
  ```sql
  A
  EXCEPT
  B
  = A − B
  ```
  ^^^

**`ORDER BY` with multiple columns** #flashcard

- Syntax:
  ```sql
  ORDER BY col1 [ASC|DESC], col2 [ASC|DESC], ...
  ```
- SQL sorts by `col1` first. If multiple rows tie on `col1`, it breaks the tie using `col2`, then `col3`, and so on.
- Think of it as **primary key → secondary key → tertiary key** for sorting.
- Example:
  ```sql
  SELECT city_code
  FROM weatherReport
  ORDER BY state, city;
  ```
  1. Sort by `state` (A–Z).
  2. Within each state, sort by `city` (A–Z).
  3. Return only `city_code`; the sorting columns need not appear in the output.
- **GATE Trap:** `ORDER BY state, city` **≠** sort by city first. The leftmost column always has the highest priority.
  ^^^

**`CHECK` constraints and `NULL`** #flashcard

- `CHECK` constraints reject a row **only if the condition evaluates to FALSE**.
- If the condition evaluates to `TRUE` \*\*or `UNKNOWN` (because of `NULL`)`, the row is accepted.
- Example:
  ```sql
  CHECK (Stock >= 0)
  ```
  - `Stock = 10` → TRUE ✅
  - `Stock = -5` → FALSE ❌
  - `Stock = NULL` → UNKNOWN ✅
- **GATE Trap:** `CHECK` does **not** imply `NOT NULL`. Add `NOT NULL` explicitly if `NULL` values are not allowed.
  ^^^

**Common SQL Constraints** #flashcard

- `PRIMARY KEY` → Unique + NOT NULL.
- `UNIQUE` → No duplicate non-NULL values (multiple `NULL`s are allowed in standard SQL).
- `NOT NULL` → Value cannot be `NULL`.
- `CHECK` → Expression must not evaluate to FALSE.
- **GATE Trap:** Constraints are checked after `INSERT`/`UPDATE` before the statement commits.
  ^^^

**Natural Join (`⋈`)** #flashcard

- Joins two relations on **all common attribute names**.
- Equivalent to:
  \[
  R \bowtie S =
  \pi*{\text{required attributes}}
  \left(
  \sigma*{\text{common attrs equal}}
  (R \times S)
  \right)
  \]
- Removes duplicate copies of common attributes.
- **GATE Trap:** Natural join is **not** Cartesian product.
  ^^^

**Natural Join vs Cartesian Product vs Theta Join** #flashcard
| Operation | Condition | Duplicate common columns? |
|-----------|-----------|---------------------------|
| `R × S` | None | Yes |
| `σ(R×S)` (Theta Join) | Explicit condition | Yes |
| `R ⋈ S` (Natural Join) | Equality on all common attributes | No |

- **GATE Trap:** A theta join followed by projection is equivalent to a natural join.
  ^^^

**SQL `LIKE` Wildcards**
?

- `%` → Matches **zero or more** characters.
- `_` → Matches **exactly one** character.
- Pattern:
  ```sql
  LIKE '30%5_%_'
  ```
  means:
  - Starts with `30`.
  - Contains a `5`.
  - Has **at least two characters after that `5`** (`_` + final `_`, with `%` matching zero or more in between).
- **GATE Trap:** `%` can match an empty string, but `_` must always match exactly one character.

# Nested Subqueries

# Database modification:

## Joins

syntax:

```sql
SELECT column1, column2, ...
FROM table1
JOIN table2
ON table1.common_column = table2.common_column;
```

- A view provides a mechanism to hide certain data from the view of certain users
- Any relation that is not of the conceptual model but is made visible to a user as a
  “virtual relation” is called a view.

example:

```sql
CREATE VIEW view_name AS
SELECT column1, column2, ...
FROM table_name
WHERE condition;
```

# Materialized Views

- A materialized view is a database object that contains the results of a query. It is similar to a view, but unlike a view, the data is actually stored on disk and can be refreshed periodically.
- Materialized views can be used to improve query performance by precomputing and storing the results of complex queries, especially in data warehousing scenarios.
- Needs to be refreshed periodically to ensure that the data is up-to-date.

## Transactions:

follows ACID properties: Atomicity, C onsistency, I solation, D urability.

## Functions/Procedures:

SYNTAX:

```sql
create function dept count (dept name varchar(20))
returns integer
begin
declare d count integer;
select count (*) into d count
from instructor
where instructor.dept name = dept name
return d cont;
end
```

select dept name, budget
from department
where dept count (dept name ) > 12
