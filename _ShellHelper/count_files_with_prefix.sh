#!/bin/bash
# count_files_with_prefix.sh
#
# Usage:
# 1) Count ONE prefix in ONE subfolder
#    ./count_files_with_prefix.sh -f <example_subfolder> -p1 <prefix>
#
# 2) Compare TWO prefixes in ONE subfolder
#    ./count_files_with_prefix.sh -f <example_subfolder> -p1 <prefixA> <prefixB>
#
# 3) Compare TWO subfolders using TWO prefixes (sum comparison)
#    ./count_files_with_prefix.sh -f <example_subfolder1> <example_subfolder2> -p2 <prefixA> <prefixB>

shopt -s nullglob

F1=""; F2=""
P1A=""; P1B=""
P2A=""; P2B=""
MODE=""

while [ $# -gt 0 ]; do
  case "$1" in
    -f) shift; F1="$1"; shift; [[ $# -gt 0 && "$1" != -* ]] && F2="$1" && shift ;;
    -p1) MODE="p1"; shift; P1A="$1"; shift; [[ $# -gt 0 && "$1" != -* ]] && P1B="$1" && shift ;;
    -p2) MODE="p2"; shift; P2A="$1"; shift; P2B="$1"; shift ;;
    *) shift ;;
  esac
done

subname() { basename "$1"; }
basedir() { dirname "$(dirname "$1")"; }
countp() { find "$1" -maxdepth 1 -type f -name "$2*" 2>/dev/null | wc -l; }

BASE1=$(basedir "$F1"); SUB1=$(subname "$F1")
BASE2=""; SUB2=""
[ -n "$F2" ] && BASE2=$(basedir "$F2") && SUB2=$(subname "$F2")

# ---------- HEADER ----------
if [ "$MODE" = "p1" ] && [ -z "$P1B" ]; then
  echo "Folder: ${SUB1} | Prefix: ${P1A}"
elif [ "$MODE" = "p1" ]; then
  echo "Folder: ${SUB1} | Prefixes: ${P1A} vs ${P1B}"
elif [ "$MODE" = "p2" ]; then
  echo "Folders: ${SUB1} vs ${SUB2} | Prefixes: ${P2A} + ${P2B}"
fi
echo "----------------------------------------"

PARTS=$(ls -1 "$BASE1" 2>/dev/null | grep -E '^[0-9]+$' | sort -n)

for ID in $PARTS; do
  D1="${BASE1}/${ID}/${SUB1}"
  [ -d "$D1" ] || continue

  if [ "$MODE" = "p1" ]; then
    cA=$(countp "$D1" "$P1A")
    if [ -z "$P1B" ]; then
      echo "$ID: $cA"
    else
      cB=$(countp "$D1" "$P1B")
      flag=$([ "$cA" -ne "$cB" ] && echo " X")
      echo "$ID: $cA | $cB$flag"
    fi

  elif [ "$MODE" = "p2" ]; then
    D2="${BASE2}/${ID}/${SUB2}"
    [ -d "$D2" ] || continue
    s1=$(( $(countp "$D1" "$P2A") + $(countp "$D1" "$P2B") ))
    s2=$(( $(countp "$D2" "$P2A") + $(countp "$D2" "$P2B") ))
    flag=$([ "$s1" -ne "$s2" ] && echo " X")
    echo "$ID: $s1 | $s2$flag"
  fi
done
