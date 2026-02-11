#!/bin/bash
# setup_fixed_mesh_and_Re.sh
# Changes physical y-size (0.5x or 2x) while keeping mesh resolution fixed

module load openfoam/7

BASE_CASE="cavity"

[ ! -d "$BASE_CASE" ] && echo "Error: No cavity directory" && exit 1

# Reynolds numbers
RE_VALUES=(10 100 300 500)

# Geometry + flow parameters
L=0.1
U=1.0

# Physical y scaling (geometry only)
declare -A Y_SCALES
Y_SCALES=( ["yHalf"]=0.5 ["yDouble"]=2.0 )

for MESH_TAG in "${!Y_SCALES[@]}"; do
    YSCALE=${Y_SCALES[$MESH_TAG]}
    YVAL=$(echo "1.0 * $YSCALE" | bc -l)

    echo "========================================"
    echo "Mesh variant: $MESH_TAG (physical y = $YVAL)"
    echo "========================================"

    for RE in "${RE_VALUES[@]}"; do
        CASE="cavity_${MESH_TAG}_Re${RE}"
        echo "Setting up $CASE"

        rm -rf "$CASE"
        mkdir -p "$CASE"

        # Copy base case
        cp -r $BASE_CASE/constant "$CASE/"
        cp -r $BASE_CASE/system   "$CASE/"
        cp -r $BASE_CASE/0        "$CASE/"

        cd "$CASE" || exit 1

        BMD="system/blockMeshDict"

        # ---- Modify blockMeshDict: scale y = 1 vertices numerically ----
        sed -i \
            -e "s/(1 1 0)/(1 $YVAL 0)/" \
            -e "s/(0 1 0)/(0 $YVAL 0)/" \
            -e "s/(1 1 0.1)/(1 $YVAL 0.1)/" \
            -e "s/(0 1 0.1)/(0 $YVAL 0.1)/" \
            "$BMD"

        # ---- Build mesh ----
        blockMesh > log.blockMesh 2>&1

        # ---- Compute viscosity from Re ----
        VISC=$(echo "$U * $L / $RE" | bc -l)

        sed -i "s/^nu.*$/nu              nu [0 2 -1 0 0 0 0] $VISC;/" \
            constant/transportProperties

        # ---- Run solver ----
        icoFoam > log.icoFoam 2>&1 &

        cd ..
        echo "Started $CASE (PID: $!)"
    done
done

echo "All cases launched."
echo "Monitor with: tail -f cavity_*/log.icoFoam"
