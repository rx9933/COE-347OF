#!/bin/bash
# simple_extract.sh

module load openfoam/9

echo "=== Simple data extraction ==="

mkdir -p simple_data

for RE in 10 100 300 500; do
    echo ""
    echo "=== Re = $RE ==="
    
    cd "cavity_Re${RE}"
    
    LAST_TIME=$(ls -d [0-9]* | sort -g | tail -1)
    echo "Time: $LAST_TIME"
    
    # Convert fields to ASCII
    foamFormatConvert -time $LAST_TIME 2>&1 | grep -v "^//"
    
    # Extract U field using a simple Python script
    python3 << EOF > ../simple_data/extract_Re${RE}.log 2>&1
import re
import numpy as np

print(f"Extracting data for Re=$RE...")

def extract_vectors(filename):
    """Extract vectors from OpenFOAM field file."""
    vectors = []
    with open(filename, 'r') as f:
        in_data = False
        for line in f:
            line = line.strip()
            if 'internalField' in line and 'nonuniform' in line:
                in_data = True
                continue
            if in_data and line.startswith('(') and line.endswith(')'):
                # Parse vector like "(0.1 0.0 0.0)"
                vec_str = line[1:-1]
                try:
                    values = [float(x) for x in vec_str.split()]
                    if len(values) == 3:
                        vectors.append(values)
                except:
                    pass
            if in_data and line.endswith(';'):
                break
    return np.array(vectors)

# Extract U field
try:
    u_data = extract_vectors('$LAST_TIME/U')
    print(f"  Extracted {len(u_data)} U vectors")
    
    # Save as text
    np.savetxt('../simple_data/U_Re$RE.txt', u_data, fmt='%.8f')
    print(f"  Saved to simple_data/U_Re$RE.txt")
    
    # Save just u components
    ux = u_data[:, 0]
    np.savetxt('../simple_data/Ux_Re$RE.txt', ux, fmt='%.8f')
    print(f"  Saved u-components to simple_data/Ux_Re$RE.txt")
    
except Exception as e:
    print(f"  Error extracting U: {e}")

# Extract points
try:
    points_data = extract_vectors('constant/polyMesh/points')
    print(f"  Extracted {len(points_data)} mesh points")
    
    # np.savetxt('../simple_data/points_Re$RE.txt', points_data, fmt='%.6f')
    print(f"  Saved to simple_data/points_Re$RE.txt")
    
    # Save x and y separately
    x = points_data[:, 0]
    y = points_data[:, 1]
    
    np.savetxt('../simple_data/x_Re$RE.txt', x, fmt='%.6f')
    np.savetxt('../simple_data/y_Re$RE.txt', y, fmt='%.6f')
    
    print(f"  Also saved x and y coordinates separately")
    
    # Try to find points near y=0.095
    mask = np.abs(y - 0.095) < 0.001
    if np.sum(mask) > 0:
        x_near = x[mask]
        if 'ux' in locals() and len(ux) == len(points_data):
            u_near = ux[mask]
            # Sort by x
            sort_idx = np.argsort(x_near)
            x_sorted = x_near[sort_idx]
            u_sorted = u_near[sort_idx]
            
            # Save near-lid data
 
            
            print(f"  Found {len(x_sorted)} points near y=0.095")
            print(f"  Saved to simple_data/near_lid_Re$RE.txt")
            
            # Show first few
            print(f"  First 5 points near lid:")
            for i in range(min(5, len(x_sorted))):
                print(f"    x={x_sorted[i]:.3f}m, u={u_sorted[i]:.6f}m/s")
    
except Exception as e:
    print(f"  Error extracting points: {e}")
EOF
    
    cd ..
done

echo ""
echo "=== Extraction complete ==="
echo ""
echo "Files created in simple_data/:"
ls -la simple_data/*.txt 2>/dev/null | head -20

echo ""
echo "=== To get your u values for force calculation ==="
echo ""
echo "For each Re, look at: simple_data/near_lid_Re*.txt"
echo "Or examine: simple_data/Ux_Re*.txt and simple_data/y_Re*.txt"
echo ""
echo "Find u at x ≈ 0.01, 0.02, ..., 0.09 m where y ≈ 0.095 m"
echo ""
echo "Then use the standard formula:"
echo "  x̃ = x/0.1"
echo "  ũ = u/1.0"
echo "  τ̃ = (1 - ũ)/0.05"
echo "  F̃ = ∫τ̃ dx̃ (trapezoidal integration)"