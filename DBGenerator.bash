#!/bin/bash
# Javier Ortiz de Artiñano	2023	Trabajo de Fin de Grado
# This script generates a dataset of Bradyrhizoium genomes.
# Dataset (found in data/):
#	- index.txt -> index of RefSeq Bradyrhizobium assemblies to be analyzed. Every row contains the following fields separated by tabs:
#	AssemblyAccn	AssemblyName	Organism	AssemblyStatus	BioprojectAccn	BioSampleAccn	ContigN50	ScaffoldN50	FtpPath_RefSeq
#	- assemblies/	-> directory containing the indexed and downloaded assemblies. The .fna files are also decompressed.


#################################################
# FUNCTIONS
#################################################

#ayuda() prints a help message
ayuda () {
   echo 'DBGenerator'
   echo 'javiortizdea 2023'
   echo -e '\nusage: DBGenerator.bash -o <output_folder> [-i] [-a] [-A] [-h]\n'
   echo -e '-o output_folder: proyect folder in which data and results will be stored.'
   echo -e "-i		: create or update the general index of assemblies (it can take some time)\n\t\tNot required if already exists."
   echo -e "-a		: download and decompress the indexed assemblies (it can take some time)\n\t\tNot required if already exists. Will not redownload already existing assemblies."
   echo -e "-A		: same as -a, but also updates all existing assemblies. Will take a good amount of time."
   echo -e "-h		: print this help and exit."
}

#indexGenerator() generates the index.txt file. Will create the data/ directory if none is found.
#It uses the Entrez API to perform the search in the NCBI Assembly database.
indexGenerator () {
	echo -e "\tGenerating master index of Bradyrhizobium assemblies..."
	if [ ! -d $projectName/data ]; then
		mkdir $projectName/data
	fi
	echo -e "#AssemblyAccession\tAssemblyName\tOrganism\tAssemblyStatus\tBioprojectAccession\tBioSample\tContigN50\tScaffoldN50\tFtpPath" > $projectName/data/index.txt 2>> $projectName/log.txt
	esearch -db assembly -query '("Bradyrhizobium"[Organism] OR bradyrhizobium[All Fields]) AND ("latest refseq"[filter] AND all[filter] NOT anomalous[filter])' | 
		efetch -format docsum | 
		xtract -pattern DocumentSummary -sep "|" -def "N/A" -element AssemblyAccession AssemblyName Organism AssemblyStatus -group RS_BioProjects -element BioprojectAccn -group DocumentSummary -def "N/A" -element BioSampleAccn ContigN50 ScaffoldN50 FtpPath_RefSeq >> $projectName/data/index.txt 2>> $projectName/log.txt
	echo -e "\tDone! Index can be found in $projectName/data/index.txt"
}

#assembliesDownloader() downloads all indexed assemblies using rsync.
#To save time, it does not redownload already downloaded assemblies,
#unless the -A option is provided to force it.
#It also decompresses the all .fna files.
assembliesDownloader () {
	if [ ! -s $projectName/data/index.txt ]; then
		echo -e "error: index not found" 1>&2
		ayuda 1>&2
		exit 1
	fi
	if [ ! -d $projectName/data/assemblies ]; then
		mkdir $projectName/data/assemblies
	fi
	echo -e "\tDownloading all indexed assemblies..."
	cat $projectName/data/index.txt | tail +2 | cut -f1 | while read assemblyAccn; do
		if [ ! -d $projectName/data/assemblies/$assemblyAccn* -o $forceUpdateAssemblies = true ]; then
			link=`cat $projectName/data/index.txt | grep "$assemblyAccn" | cut -f9 | sed -s 's/ftp:/rsync:/g'`
			echo -e "\tDownloading and decompressing $assemblyAccn..."
			rsync -rt $link $projectName/data/assemblies/ &>> $projectName/log.txt
		else 
			echo -e "\t$assemblyAccn already exists!"
		fi
		gzip -dv $projectName/data/assemblies/$assemblyAccn*/*.fna.gz &>> $projectName/log.txt
		done
	echo -e "\tDone! Assemblies can be found in $projectName/data/assemblies."
}

#################################################
# DEFAULT PARAMETERS
#################################################

projectName=false
updateIndex=false
updateAssemblies=false
forceUpdateAssemblies=false

while getopts ho:ibaA option; do
	case $option in
		h) ayuda; exit 0;;
		o) projectName=$OPTARG;;
		i) updateIndex=true;;
		b) updateBioSamples=true;;
		a) updateAssemblies=true;;
		A) updateAssemblies=true; forceUpdateAssemblies=true;;
		*) echo "error: unknown option" 1>&2; ayuda 1>&2; exit 1;;
	esac
done

#To make sure that at least the output folder name has been provided.
if [ $# -lt 1 -o $projectName = false ]; then
	echo -e "error: too few arguments" 1>&2
	ayuda 1>&2
	exit 1 
fi

#################################################
# DATA GENERATION
#################################################

#If the output folder already exists, a warning message is shown to avoid undesired information or time losses.
if [ -d $projectName ]; then
	echo -e "\tThe specified directory already exists, ¿do you want to continue?\n\tWARNING: IF '-A' OPTION IS USED, DIRECTORY DATA WILL BE OVERWRITTEN AND LOST\n\ty/n"
	read respuesta
	case $respuesta in
		y|Y) echo -e "\tThe specified directory will be used and its files will be overwritten.";;
		n|N) echo -e "\tStopping the process..."; exit 0;;
		*) echo -e "\tInvalid answer.\n\tIf you want to continue with the indicated directory, enter \"y\" o \"Y\"." 1>&2 ; echo -e "\tStopping the process.." 1>&2; exit 1;;
	esac
	rm -f $projectName/log.txt
	touch $projectName/log.txt
	if [ $updateIndex = true -o ! -s $projectName/data/index.txt ]; then
			indexGenerator
	fi
	if [ $updateAssemblies = true -o ! -d $projectName/data/assemblies ]; then
			assembliesDownloader
	fi
	else
		mkdir $projectName
		touch $projectName/log.txt
		indexGenerator
		bioSampleAttributesGenerator
		assembliesDownloader
fi