#!/bin/bash

# Usage: ./check_input_files.sh 7 12 15

if [ $# -eq 0 ]; then
    echo "Usage: $0 participant1 [participant2 ...]"
    exit 1
fi

for participant in "$@"; do
    dir="/scratch/c7201319/SNORE_MR/${participant}/Night/MR ep2d_bold_samba_2mm_sleep"
    
    if [ -d "$dir" ]; then
        count=$(find "$dir" -type f | wc -l)
        echo "Participant $participant: $count files"
    else
        echo "Participant $participant: Directory not found"
    fi
done
