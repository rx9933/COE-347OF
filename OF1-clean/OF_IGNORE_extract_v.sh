#!/bin/bash
# step1_convert.sh

module load openfoam/9

echo "Step 1: Convert to VTK"

for RE in 10 100 300 500; do
    echo "Converting Re=$RE"
    
    if [ ! -d "cavity_Re${RE}" ]; then
        continue
    fi
    
    cd "cavity_Re${RE}"
    
    LAST_TIME=$(ls -d [0-9]* 2>/dev/null | sort -g | tail -1)
    
    if [ -n "$LAST_TIME" ]; then
        echo "  Time: $LAST_TIME"
        foamToVTK -time $LAST_TIME
    fi
    
    cd ..
done

echo ""
echo "Conversion done. Now run analysis separately."