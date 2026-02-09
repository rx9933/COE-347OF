import numpy as np
import matplotlib.pyplot as plt
import os

# ============================================================
# Configuration
# ============================================================

Re_list = [10, 100, 300, 500]
vel_dir = "../simple_data"
pos_file = "../cavity_Re10_xyz.txt"   # mesh is same for all Re

os.makedirs("output", exist_ok=True)

# ============================================================
# Load mesh (nodes)
# ============================================================

pos = np.loadtxt(pos_file)

x_all = pos[:, 0]
y_all = pos[:, 1]

x = np.unique(x_all)
y = np.unique(y_all)

nx = len(x)
ny = len(y)

nx_cell = nx - 1
ny_cell = ny - 1

# Cell-center coordinates
x_cell = 0.5 * (x[:-1] + x[1:])
y_cell = 0.5 * (y[:-1] + y[1:])
dy = y_cell[1] - y_cell[0]

dx = x_cell[1] - x_cell[0]

print(f"Grid: nx={nx_cell}, ny={ny_cell}")
print(f"dx={dx}, dy={dy}")

# ============================================================
# Storage for Fe
# ============================================================

Fe_list = []

# ============================================================
# Loop over Reynolds numbers
# ============================================================

for Re in Re_list:

    print(f"\nProcessing Re = {Re}")

    vel_file = f"{vel_dir}/U_Re{Re}.txt"
    vel = np.loadtxt(vel_file)

    # Extract u-component
    u = vel[:, 0]

    # Reshape to cell-centered grid
    U_cell = u.reshape(ny_cell, nx_cell)

    # Compute du/dy (one-sided at the lid)
    dudy = np.zeros_like(U_cell)
    dudy[:-1, :] = (U_cell[1:, :] - U_cell[:-1, :]) / dy
    dudy[-1, :]  = (U_cell[-1, :] - U_cell[-2, :]) / dy

    # Top wall shear
    dudy_top = dudy[-1, :]

    # --------------------------------------------------------
    # Integrate along x to get nondimensional force Fe
    # --------------------------------------------------------
    Fe = np.trapz(dudy_top, x_cell)
    Fe_list.append(Fe)

    print(f"  Fe = {Fe:.6f}")

    # Save shear distribution (optional but nice)
    np.savetxt(
        f"output/du_dy_top_Re{Re}.txt",
        np.column_stack((x_cell, dudy_top)),
        header="x  du/dy_at_top_wall"
    )


    plt.figure(figsize=(8, 5))
    plt.plot(x_cell, dudy_top, 'b-', linewidth=2, label=f"Re={Re}")
    plt.xlabel("x position")
    plt.ylabel(r"$du/dy$ at top wall")
    plt.title(f"Shear stress distribution at top wall (Re={Re})")
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.tight_layout()
    
    plt.savefig(f"output/du_dy_top_Re{Re}.png", dpi=150)
    
    plt.show()
   
# ============================================================
# Plot Fe vs Re
# ============================================================

plt.figure(figsize=(6, 4))
plt.plot(Re_list, Fe_list, 'o-', linewidth=2)
plt.xlabel("Reynolds number (Re)")
plt.ylabel(r"Nondimensional force $F_e$")
plt.title(r"$F_e$ vs Reynolds number")
plt.grid(True, alpha=0.3)
plt.tight_layout()

plt.savefig("output/Fe_vs_Re.png", dpi=150)
plt.show()

print("\nDone.")
