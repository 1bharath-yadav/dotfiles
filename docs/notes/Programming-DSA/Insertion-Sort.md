---
subject: "Programming-DSA"
topic: "Insertion-Sort"
title: "Insertion Sort"
tags: [anki, study]
---

#srs

```python
def insertion_sort_instrumented(arr):
    """
    Insertion Sort with explicit counters for GATE analysis.
    Returns: (sorted_array, total_comparisons, total_shifts)
    """
    n = len(arr)
    comparisons = 0
    shifts = 0

    for i in range(1, n):
        key = arr[i]
        j = i - 1

        while j >= 0:
            comparisons += 1  # A comparison happens if we evaluate the condition
            if arr[j] > key:
                arr[j + 1] = arr[j]
                shifts += 1   # Count actual data shifting
                j -= 1
            else:
                break         # Stop early because the left subarray is sorted

        arr[j + 1] = key

    return arr, comparisons, shifts

# Verification using the array from Q2
if __name__ == "__main__":
    gate_array = [4, 3, 2, 10, 12, 1, 5, 6] # [cite: 40]
    _, comps, shffts = insertion_sort_instrumented(gate_array.copy())
    print(f"\nGATE Q2 Verification Metrics:")
    print(f"Total Key Comparisons: {comps}")  # Output will be 15 [cite: 52]
    print(f"Total Inversions (Shifts): {shffts}")
```

- The Number of comparisons of already sorted array of size n is n-1.
- The Number of comparisons of reverse sorted array of size n is n(n-1)/2.
- The time complexity of same number elements is O(n)

> [!warning] ⚠ Descending (reverse-sorted) array = worst case
> Every insertion requires shifting through the entire sorted prefix.
> Total shifts for a fully descending array of size n:
> $$\frac{n(n+1)}{2} - n = \frac{n(n-1)}{2}$$
> (Notes example: n=4 descending → 10 shifts total including comparisons; careful — shift count and comparison count are usually equal in the worst case since every comparison triggers a shift until the loop breaks.)

> [!tip] GATE tests these most
> - Best case (already sorted): **n−1 comparisons**, 0 shifts, O(n) time
> - Worst case (reverse sorted): **n(n−1)/2 comparisons**, n(n−1)/2 shifts, O(n²) time
> - Insertion Sort is **stable** and **in-place** (O(1) extra space)
> - Adaptive: runs faster on nearly-sorted input — GATE loves this property vs Selection Sort (never adaptive)

## Connects To
← [[Selection-Sort]] | [[Merge-Sort]]

