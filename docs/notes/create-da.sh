#!/usr/bin/env bash

set -e

# ---------- TEMPLATE WRITER ----------
create_topic() {
    local subject="$1"
    local topic="$2"

    local file="${subject}/${topic}.md"

    mkdir -p "$subject"

    cat > "$file" <<EOF
---
subject: "${subject}"
topic: "${topic}"
tags: [anki,study]
---

TARGET DECK: ${subject}::${topic}

FILE TAGS: #${subject} #${topic}

EOF
}

# ---------- SHARED MATH (USE FOR BOTH DA + PHYSICS) ----------
declare -A SUBJECTS

# Probability & Statistics (shared)
SUBJECTS["Probability-Statistics"]="\
Counting \
Probability-Axioms \
Sample-Space-Events \
Independent-Events \
Conditional-Probability \
Joint-Probability \
Bayes-Theorem \
Expectation \
Variance \
Mean-Median-Mode \
Correlation \
Covariance \
Discrete-Random-Variables \
Bernoulli \
Binomial \
Poisson \
Uniform-Distribution \
Exponential-Distribution \
Normal-Distribution \
t-Distribution \
Chi-Square-Distribution \
CDF \
Central-Limit-Theorem \
Confidence-Intervals \
Hypothesis-Testing"

# Linear Algebra (shared)
SUBJECTS["Linear-Algebra"]="\
Vector-Spaces \
Subspaces \
Linear-Independence \
Basis \
Dimension \
Projections \
Projection-Matrix \
Orthogonal-Matrix \
Idempotent-Matrix \
Quadratic-Forms \
Determinants \
Rank \
Nullity \
Linear-Systems \
Gaussian-Elimination \
Eigenvalues \
Eigenvectors \
LU-Decomposition \
SVD"

# Calculus & Optimization (shared)
SUBJECTS["Calculus-Optimization"]="\
Functions \
Limits \
Continuity \
Differentiability \
Taylor-Series \
Maxima-Minima \
Optimization"

# Programming (DA specific)
SUBJECTS["Programming-DSA"]="\
Python-Basics \
Data-Types \
Control-Structures \
Functions \
Modules \
Stacks \
Queues \
Linked-Lists \
Trees \
Hash-Tables \
Linear-Search \
Binary-Search \
Selection-Sort \
Bubble-Sort \
Insertion-Sort \
Merge-Sort \
Quick-Sort \
Graph-Theory \
BFS \
DFS \
Shortest-Path"

# Database (DA specific)
SUBJECTS["Database-Warehousing"]="\
ER-Model \
Relational-Model \
Relational-Algebra \
Tuple-Calculus \
SQL-DDL \
SQL-DML \
SQL-DCL \
Integrity-Constraints \
Normalization \
1NF \
2NF \
3NF \
BCNF \
File-Organization \
Indexing \
Discretization \
Sampling \
Compression \
Star-Schema \
Snowflake-Schema \
Concept-Hierarchies \
Measures \
OLAP"

# Machine Learning
SUBJECTS["Machine-Learning"]="\
Simple-Linear-Regression \
Multiple-Linear-Regression \
Ridge-Regression \
Logistic-Regression \
KNN \
Naive-Bayes \
LDA \
SVM \
Decision-Trees \
MLP \
Feedforward-NN \
Bias-Variance \
LOOCV \
KFold-CV \
KMeans \
KMedoids \
Hierarchical-Clustering \
PCA"

# Artificial Intelligence
SUBJECTS["Artificial-Intelligence"]="\
Uninformed-Search \
BFS-AI \
DFS-AI \
Uniform-Cost-Search \
Greedy-Best-First \
A-Star \
Minimax \
Alpha-Beta-Pruning \
Propositional-Logic \
Predicate-Logic \
Knowledge-Representation \
Conditional-Independence \
Variable-Elimination \
Monte-Carlo-Sampling"

# ---------- CREATE ----------
for subject in "${!SUBJECTS[@]}"; do
    for topic in ${SUBJECTS[$subject]}; do
        create_topic "$subject" "$topic"
    done
done

echo "GATE DA vault created."
