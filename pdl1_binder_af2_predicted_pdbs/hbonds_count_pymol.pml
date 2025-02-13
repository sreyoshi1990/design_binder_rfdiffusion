# Change to directory containing PDB files
cd /Users/ssur/Documents/rfdiffusion_test/pdl1_binder_af2_predicted_pdbs/

# Open summary output file
log_open hbond_summary.txt
print("PDB_File, Num_Hydrogen_Bonds")

# Get list of PDB files using Python
python
import glob
pdb_files = glob.glob("*.pdb")
python end

# Loop through each PDB file
python
for pdb in pdb_files:
    cmd.load(pdb)

    # Select chains (Modify if needed)
    cmd.select("binder", "chain A")
    cmd.select("target", "chain B")

    # Find hydrogen bonds between binder (A) and target (B)
    cmd.select("hbonds", "(binder within 3.5 of target) and (donor or acceptor)")

    # Count hydrogen bonds
    num_hbonds = cmd.count_atoms("hbonds")

    # Save results to the file
    with open("hbond_summary.txt", "a") as f:
        f.write(f"{pdb}, {num_hbonds}\n")
    
    print(f"{pdb}: {num_hbonds} hydrogen bonds")

    # Clear for next PDB
    cmd.delete("all")
python end

# Close the log file
log_close
print("Hydrogen bond summary saved in hbond_summary.txt")

