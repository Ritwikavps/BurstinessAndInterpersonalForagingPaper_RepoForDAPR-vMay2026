#!/bin/bash
#
# %@author info, Feb 2021
#
# This tool allows you to run the "recorderpauses.pl" tool on multiple .its files.
# The output information for each .its file is written into an individual .txt file, saved in the same folder as the .its file. After executing this file, move these output .csv files 
#to their own directory, A3_PauseTimes
#
# Takes the following command line arguments:
# The path and file for this script 
# 
# Instructions:
# 1.) To use this tool, have all desired .its files in a folder of its own. 
# 2.) In line 23, enter the path to the main folder containing the desired .its files 
# 4.) Specify the .its file
# 5.) Name the output files (lines 25)
#	  This replaces the ".its" ending of the filename to rename the file, and changes the ".its" suffix to ".txt", since the output files are .txt files
# 6.) In line 26, set the path for the "readits_start_end_content.pl" file 
# 7.) Save all changes
# 8.) Launch Terminal
# 9.) Navigate to directory where "RunFolder_readits.sh" is located
# 10.) Run this file (sh RunFolder_readits.sh )

cd ~/BaseDataPath/Data/LENAData/A1_ItsFiles  
for itsfile in *.its
	do outfile=`echo $itsfile | sed 's/\.its/_PauseTimes\.txt/g'`;
	perl ~/BaseCodePath/CodeForGitHub/A1_LENADataProcessing/recorderpauses.pl $itsfile $outfile
	done
	
