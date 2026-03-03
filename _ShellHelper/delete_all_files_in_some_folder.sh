BASE="/scratch/c7201319/SNORE_MR_out"

#RL: This is used to quickly delte all files for all participants in some folder. Change folder name below accordingly
#    Comment out the relevant parts for dry run mode or delete mode

for d in "$BASE"/*/meanEPI; do
    [ -d "$d" ] || continue
    
    #Dry Run Mode
    echo "Would remove contents of: $d"
    find "$d" -mindepth 1 -print
    
    #Actual Deletion Mode
    #echo "Removing contents of: $d"
    #rm -rf "$d"/*

done
