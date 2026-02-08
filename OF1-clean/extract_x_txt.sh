#!/bin/bash

# Simple version that directly converts OpenFOAM points files to XYZ format

folders=("cavity_Re10" "cavity_Re100" "cavity_Re300" "cavity_Re500")

for folder in "${folders[@]}"; do
    echo "Processing: $folder"
    
    if [ ! -d "$folder" ]; then
        echo "  Folder not found, skipping..."
        continue
    fi
    
    points_file="$folder/constant/polyMesh/points"
    
    if [ ! -f "$points_file" ]; then
        echo "  Points file not found, skipping..."
        continue
    fi
    
    # Extract points from OpenFOAM format
    # Find the line number where the list of points starts
    start_line=$(grep -n "^(" "$points_file" | head -1 | cut -d: -f1)
    
    if [ -z "$start_line" ]; then
        echo "  Could not find start of points data, skipping..."
        continue
    fi
    
    # Extract points (skip header, remove parentheses)
    tail -n +$((start_line + 1)) "$points_file" | \
        grep -v "^)" | \
        sed 's/[()]//g' | \
        awk 'NF==3 {printf "%.6f %.6f %.6f\n", $1, $2, $3}' > "${folder}_xyz.txt"
    
    num_points=$(wc -l < "${folder}_xyz.txt")
    echo "  Created ${folder}_xyz.txt with $num_points points"
    echo ""
done