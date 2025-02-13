Details on PDL1 pdb preprocessing and detailed results from this protocol can be found in the docx file:PDL1_binder_design.docx
I create a directory to save all the files I am using in this protocol:

```
mkdir binder_design_rf
cd binder_design_rf
```
The PDB files are obtained from MOE after doing quickprep energy minimization.
I will run this protocol in my local RFdiffusion installation. 
```
conda activate SE3nv2
cd RFdiffusion
```

**RFdiffusion run 1** \
Using the PDL1 as the target I first generated unconditional binders by providing hotspot residues that I identified using MOE in the target protein and specified the size of the binder to be 75-90 aa long.

I used the following run_inference.py command to get the designs:

```
./scripts/run_inference.py \
inference.input_pdb=../pdl1_truncated.pdb \
'contigmap.contigs=[A1-113/0 75-90]' \
inference.output_prefix=../pdl1_binder_unconditional/pdl1_binder_unconditional \
inference.num_designs=10 denoiser.noise_scale_ca=0 denoiser.noise_scale_frame=0
```

When I looked at the output pdb, they were mostly helical bunches. So I tried using a different approach where I can get a diverse output and also take into account the scaffold of the target protein.

**RFdiffusion run 2** \
For this I tried using the scaffold guided protocol. \
Here we instruct the model to take into account secondary structure information from the target protein as well as provide some scaffold templates from a library available with RFDiffusion.

First I created the secondary structure template for PDL1 and corresponding pytorch inputs using the following command :

``` ./helper_scripts/make_secstruc_adj.py --input_pdb ../pdl1_truncated.pdb --out_dir ../adj_secstr_pdl1  ```


Then I ran RFDiffusion to find binders for PDL1 using the scaffold guided protocol:

```./scripts/run_inference.py scaffoldguided.target_path=../pdl1_truncated.pdb \
inference.output_prefix=../pdl1_binder/pdl1_ss_pdl1  \
scaffoldguided.scaffoldguided=True \
'ppi.hotspot_res=[A104,A108,A9,A2,A49,A96,A106]'\
scaffoldguided.target_pdb=True  \
scaffoldguided.target_ss=../adj_secstr_pdl1/pdl1_truncated_ss.pt \
scaffoldguided.target_adj=../adj_secstr_pdl1/pdl1_truncated_adj.pt \ scaffoldguided.scaffold_dir=./ppi_scaffolds/ \
inference.num_designs=10 denoiser.noise_scale_ca=0 denoiser.noise_scale_frame=0```


**RFdiffusion run 3**

I used the make_secstruc_adj.py to generate the PD1 secondary structure from the PDB:3BIK and pytorch inputs to see if the binders can be designed with this specific binder as a scaffold. Following is the command I used:


```./helper_scripts/make_secstruc_adj.py --input_pdb ../pd1.pdb --out_dir ../adj_secstr_pd1```



I ran RFDiffusion to find binders for PDL1 using the following commandline: 


``` ./scripts/run_inference.py \
scaffoldguided.target_path=../pdl1_truncated.pdb \
inference.output_prefix=../pdl1_binder_pd1_scaffold/pdl1_ss_pdl1  \
scaffoldguided.scaffoldguided=True \
'ppi.hotspot_res=[A104,A108,A9,A2,A49,A96,A106]' \
scaffoldguided.target_pdb=True \
scaffoldguided.target_ss=../adj_secstr_pdl1/pdl1_truncated_ss.pt \
scaffoldguided.target_adj=../adj_secstr_pdl1/pdl1_truncated_adj.pt \
scaffoldguided.scaffold_dir=../adj_secstr_pd1/ \
inference.num_designs=10 denoiser.noise_scale_ca=0 denoiser.noise_scale_frame=0 


To run the scaffold based binder design protocol I had to use a different branch of the RFdiffusion repository:

```git checkout 820bfdfaded8c260b962dc40a3171eae316b6ce0```


Ultimately I got 30 different designs of PDL1 binders from RFdiffusion. But all these structures are in polyglycine sequences. So I need to use Protein MPNN to generate the relevant sequences.


**DL_binder_design protocol** \
For running the protocol of generating sequences and ultimately obtaining AF2 predicted structures from the RFdiffusion binder structures, I followed the protocol from the following paper: 
https://www.nature.com/articles/s41467-023-38328-5#Sec8


The github repo for this protocol: \
```https://github.com/nrbennet/dl_binder_design/tree/main```

This method helped in getting binders which show better experimental success, according to the paper. I wanted to ensure that my designs are relevant and can move forward for screening.

I used the following command to activate my protein-mpnn conda environment: 


```conda activate proteinmpnn_binder_design```


Then I moved all my pdbs from pdl1_binder, pdl1_binder_pd1_scaffolf, pdl1_binder_unconditional in one folder binder_design_all.

```cp pdl1_binder/*.pdb binder_design_all/
cp pdl1_binder_pd1_scaffold/*.pdb binder_design_all/
cp pdl1_binder_unconditional/*.pdb binder_design_all/```


Then I ran the following command to convert pdbs to silent files, common Rosetta file structure:

```silentfrompdbs binder_design_all/*.pdb > pdl1_binder.silent```

Next I used the silent file as input for generating sequences using proteinMPNN followed by  Rosetta structure refinement (FastRelax) on the backbone. 
```
dl_interface_design.py -silent pdl1_binder.silent -outsilent pdl1_binder_proteinmpnn.silent```

Then we used the sequences generated from dl_interface_design protocol to generate the alphafold structures for all 30 different designs alongwith the PDL1 protein.\
```conda activate af2_binder_design3```

```predict.py -silent pdl1_binder_proteinmpnn.silent -outsilent pdl1_binder_af2.silent```

This generates the out.asc file which contains the scoring of the AF2 predicted binder to the ones generated by RFdiffusion.\
In this file we are most interested in the pae_interaction, the lower the value the better prediction of the interaction between PDL1 and binder designs. This interaction is also correlated to the  binder_aligned_rmsd which compares the RFDiffusion structure to the Alphafold predicted structure with C-alpha RMSD.

I used Rosetta's extract_pdb tool to get pdb from the silent file, pdl1_binder_af2.silent:


```extract_pdbs.linuxgccrelease -in:file:silent pdl1_binder_af2.silent -in:file:silent_struct_type binary -out:pdb ```

The final structures are stored in this directory: pdl1_binder_af2_predicted_pdbs

I ran the following bash command to show the top designs with pae_interaction<20 parameter calculated by AF2:

```
awk 'NR==1 || $4 < 20' out.sc | sort -r -k4,4n```

Following is the output :\
SCORE:     binder_aligned_rmsd pae_binder pae_interaction pae_target plddt_binder plddt_target plddt_total target_aligned_rmsd time description \
SCORE:        0.488    2.839    5.164    2.632   92.580   95.089   93.976    1.114  413.295        pdl1_binder_unconditional_1_dldesign_0_cycle1_af2pred \
SCORE:        0.650    4.024    7.129    2.605   87.207   94.595   91.423    1.423  380.267        pdl1_binder_unconditional_0_dldesign_0_cycle1_af2pred \
SCORE:        0.591    2.981    8.080    2.619   90.683   94.470   92.936    1.802  372.959        pdl1_binder_unconditional_3_dldesign_0_cycle1_af2pred \
SCORE:        1.168    7.229   11.719    2.777   68.806   92.115   82.742    2.130  180.076        pdl1_binder_unconditional_9_dldesign_0_cycle1_af2pred \
SCORE:        2.336    7.840   17.523    3.548   73.545   95.137   90.895    5.915  194.437        pdl1_ss_pdl1_3_dldesign_0_cycle1_af2pred \
SCORE:        0.953    3.757   18.068    2.691   87.642   94.948   91.987    2.321  173.476        pdl1_binder_unconditional_8_dldesign_0_cycle1_af2pred 

I used pymol to look at the structures and we found quite interesting structures as shown in the Word document.

I also wrote some pymol scripts to measure the h-bonds between binder and PDL1 and the sum of residue charges in the hydrophobic core of the AF2 predicted binder structures.

These scripts need to be run in Pymol by going to File -> Run Scripts...

The script names are : \
pdl1_binder_af2_predicted_pdbs/buried_charges_corr_pymol.pml with output buried_charges_summary.txt \
pdl1_binder_af2_predicted_pdbs/hbonds_count_pymol.pml with output hbond_summary.txt


To rank the final binder structures based on the h-bonds calculation I ran the following command:\
```awk -F, 'NR==1 {print; next} {print | "sort -t, -k2,2nr"}' hbond_summary.txt```


```python

```
