#!/bin/bash

# Script to fix README by removing everything after "📚 **Documentation**" section
# This removes broken links and cleans up the documentation

set -e

echo "🔧 Fixing README by removing content after Documentation section..."

# Find README files (case insensitive)
readme_files=$(find . -maxdepth 1 -iname "readme*" -type f 2>/dev/null || true)

if [ -z "$readme_files" ]; then
    echo "ℹ️ No README file found in the current directory"
    exit 0
fi

for readme_file in $readme_files; do
    echo "📝 Processing: $readme_file"

    if [ ! -f "$readme_file" ]; then
        echo "⚠️ File $readme_file not found, skipping..."
        continue
    fi

    # Check if the file contains the target section
    if ! grep -q "📚 \*\*Documentation\*\*" "$readme_file"; then
        echo "ℹ️ No '📚 **Documentation**' section found in $readme_file, skipping..."
        continue
    fi

    # Create a backup
    cp "$readme_file" "$readme_file.bak"
    echo "💾 Created backup: $readme_file.bak"

    # Find the line number of "📚 **Documentation**" and remove everything from that line onwards
    line_num=$(grep -n "📚 \*\*Documentation\*\*" "$readme_file" | head -1 | cut -d: -f1)

    if [ -n "$line_num" ] && [ "$line_num" -gt 0 ]; then
        # Calculate the line before the Documentation section
        end_line=$((line_num - 1))

        # Keep only the content up to the line before the Documentation section
        head -n "$end_line" "$readme_file" > "$readme_file.tmp"
        mv "$readme_file.tmp" "$readme_file"

        echo "✅ Successfully removed content from line $line_num onwards in $readme_file"
        echo "📊 Original file had $(wc -l < "$readme_file.bak") lines, now has $(wc -l < "$readme_file") lines"
    else
        echo "⚠️ Could not determine line number for Documentation section in $readme_file"
    fi
done

echo "🎉 README fixing completed!"