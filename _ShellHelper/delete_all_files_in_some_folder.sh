BASE="/scratch/c7201319/SNORE_MR_out"

for d in "$BASE"/*/skull_stripp; do
    [ -d "$d" ] || continue
    
    #Dry Run Mode
    #echo "Would remove contents of: $d"
    #find "$d" -mindepth 1 -print
    
    #Actual Deletion Mode
    echo "Removing contents of: $d"
    rm -rf "$d"/*

done
