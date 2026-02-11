#!/bin/bash

mkdir -p simple_data

for term in yDouble yHalf; do
  for RE in 10 100 300 500; do
    case_dir="cavity_${term}_Re${RE}"

    if [ ! -d "$case_dir" ]; then
      echo "Skipping $case_dir (not found)"
      continue
    fi

    # get latest time directory
    time_dir=$(ls -d $case_dir/[0-9]* | sort -g | tail -1)

    echo "Processing $case_dir (time=$time_dir)"

    # extract full U vectors
    awk '
    /internalField[[:space:]]+nonuniform/ {
        getline   # number of entries
        getline   # opening "("
        read=1
        next
    }
    read && /^\(/ {
        gsub(/[()]/,"")       # remove parentheses
        print                  # print full line
    }
    read && /^\)/ {
        exit
    }
    ' "$time_dir/U" > "simple_data/U_${term}_Re${RE}.txt"
  done
done

echo "Done. Files created in simple_data/"
