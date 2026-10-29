#!/usr/bin/env bash
set -u
shopt -s nullglob nocaseglob

file=""
dir=""

while (($#)); do
  case "$1" in
    --file)
      [[ $# -ge 2 ]] || { echo "Missing PDF path"; exit 1; }
      file="$2"; shift 2 ;;
    --dir)
      [[ $# -ge 2 ]] || { echo "Missing directory path"; exit 1; }
      dir="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 --file FILE.pdf | --dir DIRECTORY"
      exit 0 ;;
    *)
      echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -n "$file" && -n "$dir" ]]; then
  echo "Use either --file or --dir, not both."
  exit 1
fi

if [[ -n "$file" ]]; then
  [[ -f "$file" ]] || { echo "File not found: $file"; exit 1; }
  pdfs=("$file")
elif [[ -n "$dir" ]]; then
  [[ -d "$dir" ]] || { echo "Directory not found: $dir"; exit 1; }
  pdfs=("$dir"/*.[pP][dD][fF])
else
  echo "Usage: $0 --file FILE.pdf | --dir DIRECTORY"
  exit 1
fi

[[ ${#pdfs[@]} -gt 0 ]] || { echo "No PDF files found."; exit 1; }

folder="${dir%/}"
[[ -n "$folder" ]] || folder="."
out="$(basename "$folder")_transcript.md"
[[ -n "$file" ]] && out="$(basename "${file%.*}")_transcript.md"
: > "$out"

for pdf in "${pdfs[@]}"; do
  md="${pdf%.*}.md"
  echo "Processing: $pdf"

  markitdown "$pdf" -o "$md" || continue

  sed -E \
    -e '/Refer Slide Time:/d' \
    -e '/^Hello everyone and welcome/d' \
    -e '/^Professor/d' \
    -e '/^Department/d' \
    -e '/^Indian Institute of Technology, Madras/d' \
    -e '/^Modern Application Development - I/d' \
    -e '/^[[:space:]]*L[[:space:]]*$/d' \
    "$md" >> "$out"

  printf '\\n\\n' >> "$out"
done

echo "Transcript saved to: $out"
