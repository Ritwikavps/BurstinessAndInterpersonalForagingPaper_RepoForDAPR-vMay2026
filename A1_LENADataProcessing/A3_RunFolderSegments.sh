#!/bin/bash

# %@author info, Feb 2021 (modified from code by @author info; originally available on [removed for DAPR], see repo for additional documentation)

#This tool allows you to run the "segments.pl" tool on multiple .its files.
#The output information for each .its file is written into an individual .csv file which will be stored in the same folder as the .its file. After executing this file, move these output .csv files 
#to their own directory, A2_Segments
#
# Takes the following command line arguments:
# The path and file for this script 
# 
# Instructions:
# 1.) To use this tool, have all desired .its files in a folder of its own. You may nest folders for each participant within the overall folder. 
# 2.) Enter the path to the main folder containing the desired .its files 
# 3.) Specify the .its file
# 4.) Name the output file
#	  This adds "_out" to the end of the .its filename, and changes the ".its" suffix to ".csv", since the output file is a .csv file
# 5.) Set the path for the "segments.pl" file 
# 6.) Save all changes
# 7.) Launch Terminal
# 8.) Navigate to directory where "RunFolder_segments.sh" is located
# 9.) Run the file (sh RunFolder_segments.sh )

cd ~/BaseDataPath/Data/LENAData/A1_ItsFiles
for itsfile in *.its
	do outfile=`echo $itsfile | sed 's/\.its/_Segments\.csv/g'`  
	perl ~/BaseCodePath/CodeForGitHub/A1_LENADataProcessing/segments.pl $itsfile $outfile 
done

