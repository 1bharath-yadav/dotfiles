---
subject: "Programming-DSA"
topic: "Selection-Sort"
title: "Selection Sort"
tags: [anki, study]
---

#flashcards

```python
def selection_sort(arr):
n = len(arr)

    # Traverse through all array elements
    for i in range(n):
        # Assume the current element is the minimum
        min_idx = i

        # Scan the rest of the array to find the actual minimum
        for j in range(i + 1, n):
            if arr[j] < arr[min_idx]:
                min_idx = j

        # Swap the found minimum element with the first element
        arr[i], arr[min_idx] = arr[min_idx], arr[i]

    return arr
```

# Example usage:

unsorted_list = [64, 25, 12, 22, 11]
sorted_list = selection_sort(unsorted_list)
print("Sorted array:", sorted_list)

# Output: [11, 12, 22, 25, 64]

- Time complexity is O(n^2) in all cases (best, average, and worst) because of the two nested loops.
- Space complexity is O(1) as it sorts the array in place without using any additional data structures.
- stability: Selection sort is not a stable sorting algorithm. It may change the relative order of equal elements.
- comparisons made: The number of comparisons made by selection sort is always the same, which is n(n-1)/2, where n is the number of elements in the array. This is because for each element, it compares with every other element in the unsorted portion of the array.

  > [!Misconception]
  > Don't need to compare the first element,it just enough to find minimum element in the unsorted portion of the array. The first element is already considered as the minimum at the start of each iteration.

  > [!Misconception]
  > we should compare the first element with the rest of the elements in the unsorted portion to ensure we find the true minimum. The first element is only assumed to be the minimum at the start of each iteration, but it may not be the actual minimum.

- Question: Does Selection Sort become unstable only when it directly swaps two equal elements?
  ?
  > [!Misconception]
  > Equal elements change order only if they are directly swapped with each other.
  
  > [!Correction]
  > Equal elements can change order **indirectly** when one is swapped with a smaller element, reversing their relative order. Stability depends on preserving the original order of equal elements, not on direct swaps.
<!--SR:!fsrs,2026-07-07T03:13:27.840Z,7,7.31530068,2.11121424,2,2,0,0,2026-06-30T03:13:27.840Z-->

> [!danger] ⚠ Corrected: self-swap still counts as a swap
> If `min_idx == i` (element already in correct position), the code still executes `arr[i], arr[min_idx] = arr[min_idx], arr[i]`.
> This is a **self-swap** — no-op in effect but GATE questions that ask "how many swap *operations* occur" count it. Total swap operations = **n − 1** (last element never needs a pass), regardless of how many are self-swaps.

> [!tip] Invariant to hold in your head
> After the $i$-th outer loop iteration, `arr[0..i]` is sorted **and** contains the $i+1$ smallest elements from the original array — not just "sorted so far," but globally the correct minimums.

## Connects To
← [[Insertion-Sort]] | [[Merge-Sort]]


