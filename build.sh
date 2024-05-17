#!/bin/bash

# Parse meta.yaml into a table
IFS=$'\n' externalLibs=($(yq e '.["external-libs"]' meta.yaml | awk 'BEGIN{FS="#"}{print $1}' | grep -v '^$'))
ignoreFiles=$(yq e '.ignore[]' meta.yaml | awk 'BEGIN{FS="#"}{print $1}' | grep -v '^$')

# Find all .toc files and read them into an array
readarray -d '' tocs < <(find . -name "*.toc" -print0)

# Iterate over each .toc file
for toc in "${tocs[@]}"; do
    name=$(grep -oP '## Title: \K.*' "$toc" | sed -r 's/(\|cff[a-fA-F0-9]{6})//g;s/(\|r)//g' | tr -d '\r')
    # name=$(echo "$name" | tr -cd '[:alnum:]\n\r')
    version=$(grep -oP '## Version: \K.*' "$toc" | tr -d '\r')
    
    includeFiles=("$toc" "README.md" "CHANGELOG.md")
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

# Create a directory for the build
build_dir="build/$name"
mkdir -p "$build_dir"

# Copy the addon files to the build directory
for file in "${includeFiles[@]}"; do
    file=$(echo $file | tr '\\' '/')
    cp --parents "$file" "$build_dir"
done

# printf '%s\n' "${includeFiles[@]}"
# printf '%s\n' "${externalLibs[@]}"
# echo "externalLibs: ${externalLibs[@]}"

# Copy external libraries to the build directory
cd "$build_dir"
mkdir "libs"
cd "libs"
for lib in "${externalLibs[@]}"; do
    # Split the library name and the URL
    IFS=':' read -r lib_name lib_url <<< "$lib"
    # Remove leading and trailing whitespace
    lib_name=$(echo "$lib_name" | xargs)
    lib_url=$(echo "$lib_url" | xargs)
    echo "Downloading $lib_name from $lib_url"
    # Download the library with svn
    svn export --force "$lib_url" "$lib_name"
done
# Zip the built addon
cd ../..
zip -r "$name-$version.zip" "$name"
# return the name of the addon
echo "$name" > addonName.txt
# return to the root directory
cd -