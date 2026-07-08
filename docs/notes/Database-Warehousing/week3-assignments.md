---
id: week3-assignments
aliases: []
tags: []
---

#srs

Second-highest value vs second row
?

- Second-highest **value** ≠ second row after sorting.
- `ORDER BY ... LIMIT 1 OFFSET 1` returns the **second row**.
- It fails when the highest value appears multiple times.
- Use `MAX(runs) WHERE runs < (SELECT MAX(runs)...)` for the second-highest **distinct** value.

Misconception: `LIMIT 1 OFFSET 1` always finds the second-highest score.
?

- False.
- It skips only one row, not one distinct value.
- Duplicate highest values break this approach.
- Safe method: nested `MAX()` or `DENSE_RANK()`.

Employees with no dependents
?

- Use a correlated `NOT EXISTS`.
- Think: "Return employee if no matching dependent exists."
- Pattern:
  `NOT EXISTS (SELECT * FROM Dependent WHERE Employee.ssn = Dependent.essn)`

`NEW` and `OLD` in triggers
?

- `NEW` and `OLD` are available only in **row-level triggers**.
- Always check for `FOR EACH ROW`.
- Statement-level triggers cannot use `NEW`/`OLD`.
