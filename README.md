# TFG_Brady
All code developed for the Bachelor's Thesis "Phylogenomic analysis of type VI secretion systems in the genus Bradyrhizobium", belonging to the BSc in Biotechnology of the Polytechnic University of Madrid.

Workflow:
1. Run DBGenerator.bash to download Bradyrhizobium assemblies and index them.
2. Run DB1_MultiFastaGenerator.ipynb with Jupyter Notebook to generate a multifasta file with DB1.
3. Run makeblastDB1.bash to generate DB1.
4. Run BLASTP analysis on DB2 with BLASTPAnalyzer.bash. To continue, a list with hcp, vgrG and tssB loci must be obtained. (Format: assembly_accession!contig_id@locus_name)
5. Run DB2_NeighborFinder.ipynb with Jupyter Notebook to find the closest loci. From there, modify the output with bash and BioPython to obtain the DB2 multifasta file.
6. Run makeblastDB2.bash to generate DB2.
7. Run BLASTP analysis on DB2 with BLASTPAnalyzer.bash.
