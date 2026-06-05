#@author info, Oct 2023
#This script parses .its files and saves infant age details in a .csv file (this is a far less clunky implementation of code of the sameconcept that uses a combo of 
#Bash, Perl, and MATLAB)

library(pracma); library(sjmisc); library(tidyverse) #Load required libraries

################################################################################################################################################################################################################################
#CHANGE PATHS ACCORDINGLY
#Source all user-defined functions
source('~/BaseCodePath/CodeForGitHub/A1_LENADataProcessing/ItsParsingFnsForInfantAge.R')
BasePath <- '~/BaseDataPath/'
setwd(str_c(BasePath,'LENAData/A1_ItsFiles/')) #Set working directory
ItsFileTab <- read_csv(str_c(BasePath,'MetadataFiles/ItsFileDetailsShareable.csv')) #Read metadata file
OpFileName <- str_c(BasePath,'MetadataFiles/MetadataInfAgeAndID.csv') #Get output file name
################################################################################################################################################################################################################################

CurrPath <- getwd() #Get current path
ItsDir <- dir(CurrPath, pattern = ".its") #dir .eaf files

FNRoot <- c(); InfantAge <- c(); InfantID <- c() #Initialise vectors to iteratively populate

for (i in 1:numel(ItsDir)) { #Go through files dir-d
  ItsFilename <- ItsDir[i] #Set ItsFilename variable as .its file name 
  FNRoot[i] <- gsub('.its','',ItsFilename); InfantAge[i] <- GetInfAge(ItsFilename); InfantID[i] <- GetInfantID(ItsFileTab,ItsFilename)
}

AgeTbl <- tibble(FNRoot,InfantID,InfantAge); write_csv(AgeTbl,OpFileName) #Make and write output table