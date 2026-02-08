#!/bin/bash
# setup_fixed.sh - Copy and modify original transportProperties

module load openfoam/7

[ ! -d "cavity" ] && echo "Error: No cavity directory" && exit 1

# Reynolds numbers
RE_VALUES=(10 100 300 500)
L=0.1
U=1.0

for RE in "${RE_VALUES[@]}"; do
    echo "Setting up Re=$RE"
    DIR="cavity_Re${RE}"
    
    # Clean and copy
    rm -rf "$DIR"
    mkdir -p "$DIR"
    
    # Copy only essential directories (excluding results)
    cp -r cavity/constant "$DIR/"
    cp -r cavity/system "$DIR/"
    cp -r cavity/0 "$DIR/"  # Keep 0 for initial conditions
    
    cd "$DIR"
    
    # Calculate viscosity
    VISC=$(echo "$U * $L / $RE" | bc -l)
    
    # Keep original header, just modify the nu value
    sed -i "s/^nu.*$/nu              nu [0 2 -1 0 0 0 0] $VISC;/" constant/transportProperties
    
    # Run
    blockMesh > log.blockMesh 2>&1
    icoFoam > log.icoFoam 2>&1 &
    
    cd ..
    echo "Started Re=$RE (PID: $!)"
done

echo "Done. Check: tail -f cavity_Re*/log.icoFoam"