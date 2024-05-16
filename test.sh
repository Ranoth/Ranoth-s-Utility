#!/bin/bash

# Parse meta.yaml into a table
externalLibs=$(yq e '.["external-libs"]' meta.yaml | awk 'BEGIN{FS="#"}{print $1}' | grep -v '^$')
ignoreFiles=$(yq e '.ignore[]' meta.yaml | awk 'BEGIN{FS="#"}{print $1}' | grep -v '^$')

# Find all .toc files and read them into an array
readarray -d '' tocs < <(find . -name "*.toc" -print0)

# Iterate over each .toc file
for toc in "${tocs[@]}"; do
    name=$(grep -oP '## Title: \K.*' "$toc" | sed -r 's/(\|cff[a-fA-F0-9]{6})//g;s/(\|r)//g' | tr -d '\r')
    name=$(echo "$name" | tr -cd '[:alnum:]\n\r')
    version=$(grep -oP '## Version: \K.*' "$toc" | tr -d '\r')

    includeFiles=("$toc" "README.md")
    while IFS=$'\r' read -r line; do
        # Ignore lines that do not represent file paths
        if [[ $line == \#* ]] || [[ $line == "" ]]; then
            continue
        fi
        # Replace backslashes with forward slashes
        line=${line//\\//}
        # If line is empty after replacing, continue to the next iteration
        if [[ $line == "" ]]; then
            continue
        fi
        includeFiles+=("$line")
    done < <(grep -v -e '^#' -e '^$' "$toc")
    
    # Exclude files from ignoreFiles
    for ignoreFile in "${ignoreFiles[@]}"; do
        includeFiles=("${includeFiles[@]/$ignoreFile}")
    done
done