# Change to directory containing PDB files
cd /Users/ssur/Documents/rfdiffusion_test/pdl1_binder_af2_predicted_pdbs/

# Open summary output file
log_open buried_charges_corr_summary.txt
print("PDB_File, Num_Buried_Charged_Residues, Total_Buried_Charge")

# Get list of PDB files using Python
python
import glob
pdb_files = glob.glob("*.pdb")
python end

# Loop through each PDB file
python
for pdb in pdb_files:
    cmd.load(pdb)

    # Compute SASA for all residues
    cmd.set("dot_solvent", 1)
    cmd.get_area("all", load_b=1)

    # Select buried residues (SASA < 5.0 Å²)
    cmd.select("buried_residues", "all and b < 5.0")

    # Select charged residues *only in buried regions*
    cmd.select("buried_charged", "buried_residues and resn ARG+LYS+ASP+GLU+HIS")

    # Count unique buried charged residues
    unique_buried_residues = set()
    total_charge = 0

    stored.list = []
    cmd.iterate("buried_charged", "stored.list.append((resi, resn))")

    for resi, resn in stored.list:
        if (resi, resn) not in unique_buried_residues:
            unique_buried_residues.add((resi, resn))
            
            # Assign charge based on residue type
            if resn == "ARG" or resn == "LYS":
                total_charge += 1  # Positive charge
            elif resn == "ASP" or resn == "GLU":
                total_charge -= 1  # Negative charge
            elif resn == "HIS":
                total_charge += 0.5  # Histidine is partially charged

    num_buried_charges = len(unique_buried_residues)

    # Save results to the file
    with open("buried_charges_summary.txt", "a") as f:
        f.write(f"{pdb}, {num_buried_charges}, {total_charge}\n")
    
    print(f"{pdb}: {num_buried_charges} buried charged residues, Total charge: {total_charge}")

    # Clear for next PDB
    cmd.delete("all")
python end

# Close the log file
log_close
print("Buried charged residues summary saved in buried_charges_summary.txt")
