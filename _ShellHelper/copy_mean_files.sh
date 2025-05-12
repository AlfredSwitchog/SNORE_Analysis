#!/bin/bash

# Usage: ./copy_mean_files.sh /path/to/source /path/to/destination

# Check that exactly two arguments are given
if [ $# -ne 2 ]; then
    echo "Usage: $0 <source_directory> <destination_directory>"
    exit 1
fi

from_dir="$1"
to_dir="$2"

# Check that source directory exists
if [ ! -d "$from_dir" ]; then
    echo "Source directory not found: $from_dir"
    exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$to_dir"

# Copy files that contain "mean" in their names
find "$from_dir" -type f -name '*mean*' -exec cp {} "$to_dir" \;

echo "Done. Copied all files with 'mean' in the name from $from_dir to $to_dir."
