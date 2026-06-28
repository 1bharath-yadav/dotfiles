#!/usr/bin/env bash

set -e

# ---------- TEMPLATE WRITER ----------
create_concept() {
    local subject="$1"
    local topic="$2"
    local concept="$3"

    # Standardize names to clean snake_case for directories and files
    local sub_dir
    local top_dir
    local file_name
    sub_dir=$(echo "$subject" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    top_dir=$(echo "$topic" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    file_name=$(echo "$concept" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')

    local target_dir="${sub_dir}/${top_dir}"
    mkdir -p "$target_dir"

    cat > "${target_dir}/${file_name}.md" <<EOF
---
subject: "${subject}"
topic: "${topic}"
title: "${concept}"
tags: [anki, study, gate_da]
---

TARGET DECK: ${subject}::${topic}::${concept}

FILE TAGS: #${sub_dir} #${top_dir} #${file_name}

## ${concept} Notes

### Core Formulas & Properties
- 

### Common GATE Question Patterns
- 

### Flashcards (Anki)
- 
EOF
}

# ---------- GRANULAR SYLLABUS DATA ----------

# 1. QUANTITATIVE APTITUDE
while read -r concept; do
    [[ -z "$concept" ]] && continue
    create_concept "Quantitative Aptitude" "Data Interpretation" "$concept"
done <<'EOF'
Bar Graphs and Histograms
Pie Charts and Share Distribution
Line Graphs and Trend Analysis
2D and 3D Plot Interpretation
Unstructured Tables and Missing Data Maps
EOF

while read -r concept; do
    [[ -z "$concept" ]] && continue
    create_concept "Quantitative Aptitude" "Numerical Computation and Estimation" "$concept"
done <<'EOF'
Ratios Proportions and Direct Inverse Variations
Percentages Profit Loss and Compound Discounts
Powers Exponents and Surds Simplification
Logarithms Properties and Series
Permutations and Combinations Counting Rules
Arithmetic and Geometric Progressions Infinite Series
Time Speed Distance and Relative Velocity
Time Work and Pipe Cistern Efficiencies
EOF

while read -r concept; do
    [[ -z "$concept" ]] && continue
    create_concept "Quantitative Aptitude" "Mensuration and Geometry" "$concept"
done <<'EOF'
Lines Angles and Triangle Congruence Properties
Polygons Circles Perimeter and Area
3D Surface Areas and Volumes Cubes and Spheres
Coordinate Geometry Basics and Coordinate Distance
EOF

while read -r concept; do
    [[ -z "$concept" ]] && continue
    create_concept "Quantitative Aptitude" "Elementary Statistics and Probability" "$concept"
done <<'EOF'
Mean Median Mode and Standard Deviation
Basic Probability Events and Sample Spaces
Conditional Probability and Independent Events
EOF


# 2. ANALYTICAL APTITUDE
while read -r concept; do
    [[ -z "$concept" ]] && continue
    create_concept "Analytical Aptitude" "Logic and Reasoning" "$concept"
done <<'EOF'
Deductive Logic and Syllogisms
Inductive Logic and Pattern Inference
Truth Teller and Liar Puzzles
Alphanumeric Series and Coding Decoding
EOF

while read -r concept; do
    [[ -z "$concept" ]] && continue
    create_concept "Analytical Aptitude" "Relations and Arrangements" "$concept"
done <<'EOF'
Linear and Circular Seating Arrangements
Blood Relations and Family Trees
Direction Sense and Network Path Traversal
Age Related Mathematical Puzzles
EOF

while read -r concept; do
    [[ -z "$concept" ]] && continue
    create_concept "Analytical Aptitude" "Analogy" "$concept"
done <<'EOF'
Verbal and Concept Word Analogies
Numerical Analogy and Logic Mapping
EOF


# 3. SPATIAL APTITUDE
while read -r concept; do
    [[ -z "$concept" ]] && continue
    create_concept "Spatial Aptitude" "Transformation of Shapes" "$concept"
done <<'EOF'
2D Coordinate Translation and Sliding
Mental Rotation of 2D and 3D Objects
Dimensional Scaling and Proportions
Mirroring and Axis Reflections
EOF

while read -r concept; do
    [[ -z "$concept" ]] && continue
    create_concept "Spatial Aptitude" "Assembling and Grouping" "$concept"
done <<'EOF'
Geometric Block Assembly
Missing Piece Identification Mosaic
EOF

while read -r concept; do
    [[ -z "$concept" ]] && continue
    create_concept "Spatial Aptitude" "Paper Folding and Patterns" "$concept"
done <<'EOF'
Paper Folding and Hole Punch Unfolding Visuals
Embedded and Hidden Figure Detection
2D Net to 3D Cube Folding Patterns
EOF


# 4. VERBAL APTITUDE
while read -r concept; do
    [[ -z "$concept" ]] && continue
    create_concept "Verbal Aptitude" "Basic English Grammar" "$concept"
done <<'EOF'
Tenses and Aspect Usage
Articles and Determiners
Prepositions and Conjunctions
Subject Verb Agreement and Subject Predicate Match
Sentence Correction and Spotting Errors
EOF

while read -r concept; do
    [[ -z "$concept" ]] && continue
    create_concept "Verbal Aptitude" "Vocabulary" "$concept"
done <<'EOF'
Contextual Synonyms and Antonyms
Idioms Phrases and Phrasal Verbs
Word Analogy Maps
EOF

while read -r concept; do
    [[ -z "$concept" ]] && continue
    create_concept "Verbal Aptitude" "Reading Comprehension and Analysis" "$concept"
done <<'EOF'
Central Theme Extraction
Author Inference and Logic Extraction
Critical Reasoning Assertions and Assumptions
EOF

while read -r concept; do
    [[ -z "$concept" ]] && continue
    create_concept "Verbal Aptitude" "Narrative Sequencing" "$concept"
done <<'EOF'
Para jumbles and Sentence Ordering
Contextual Sentence Completion Cloze Tests
EOF

echo "Deep-dive Concept-level GATE GA vault created successfully."
