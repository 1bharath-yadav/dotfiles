---
subject: "Programming-DSA"
topic: "Merge-Sort"
title: "Merge Sort"
tags: [anki, study]
---

#flashcards

```python
def merge_sort(arr):
    """
    Standard Divide and Conquer Merge Sort Implementation.
    Time Complexity: O(n log n) across all cases.
    Space Complexity: O(n) auxiliary memory.
    """
    if len(arr) <= 1:
        return arr

    # 1. Divide: Find the midpoint
    mid = len(arr) // 2

    # Recursively split and sort both halves
    left_half = merge_sort(arr[:mid])
    right_half = merge_sort(arr[mid:])

    # 2. Conquer: Merge the sorted halves
    return merge(left_half, right_half)


def merge(left, right):
    sorted_arr = []
    i = j = 0

    # Compare elements from both sub-lists
    while i < len(left) and j < len(right):
        # Using <= ensures the algorithm remains STABLE
        if left[i] <= right[j]:
            sorted_arr.append(left[i])
            i += 1
        else:
            sorted_arr.append(right[j])
            j += 1

    # Append any remaining elements left over
    sorted_arr.extend(left[i:])
    sorted_arr.extend(right[j:])

    return sorted_arr

# Verification
if __name__ == "__main__":
    test_arr = [4, 3, 2, 10, 12, 1, 5, 6]
    print("Original:", test_arr)
    print("Sorted:  ", merge_sort(test_arr))
```

Does using a multi-way split (e.g., 3-way or 4-way) lower Merge Sort's asymptotic complexity?
?

- **No.**
- Splitting into $k$ parts yields the recurrence:
  $$T(n) = k T(n/k) + \Theta(n)$$
- According to Master's Theorem, the solution is always:
  $$\Theta(n \log_k n) = \Theta\left(n \frac{\log_2 n}{\log_2 k}\right) = \Theta(n \log_2 n)$$
- While it changes the base of the logarithm, the **asymptotic growth class remains completely unchanged**.

How many comparisons are needed to merge multiple sorted arrays using divide-and-conquer?
?

- Merge two sorted arrays of sizes m and n using **m+n−1** comparisons (worst case).
- Build the merge tree level by level.
- Total = sum of comparisons at every merge level.
- Example: 8 arrays × 4 elements → 4×7 + 2×15 + 1×31 = **89**.

How many recursive calls does Merge Sort make for an array of length n?
?
- For n = 8: split tree is 8→(4,4)→(2,2,2,2)→(1,1,1,1,1,1,1,1).
- Total recursive calls (including leaf base-case returns) = **2n − 2** for n a power of 2, i.e. 14 calls for n=8.
- General shape: each internal node makes 2 recursive calls; total internal nodes = n−1, total calls = 2(n−1).

> [!note] Added by agent — worst-case total comparisons across a merge tree
> Comparisons per merge level of two runs sized m,n: **m + n − 1**.
> For a full binary merge tree of depth $\log_2 n$, total worst-case comparisons sum via arithmetic series:
> $$\frac{n}{2}\left[2a + (n-1)d\right]$$
> where a = first-level comparisons, d = increment per level.
> ⭐ GATE PRIORITY: this m+n−1 formula is the single most tested Merge Sort fact — memorize it over the general recurrence.

> [!example] Master Theorem shape (used for Merge Sort recurrence)
> $$T(n) = aT(n/b) + f(n)$$
> - $a$ = number of subproblems, $b$ = size divisor, $f(n)$ = work done outside recursion (the merge step)
> - Merge Sort: $a=2, b=2, f(n)=\Theta(n)$ → $T(n) = \Theta(n \log n)$ by Case 2 of Master Theorem.

