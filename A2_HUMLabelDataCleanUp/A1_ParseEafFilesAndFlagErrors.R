#%@author info, May 2022; modified Nov 2023
#code to parse .eaf files and save annotation details (start time ref, start time ref linenum, start time value; 
#end time ref, end time ref line num, end time value; annotation id, annotation id line num, annotation value, anotation value line num;
#tier id type)

#In addition, also output summary files for any flags (missing infant voc type, adult utt dir, and adult orthographic transcription tiers + info about when the
#or if there is a mismatch in the number of different details corresponding to each annottaion

#load required librarues
library(pracma) #lots fo basic functions
library(stringr)
library(sjmisc)

################################################################################################################################################################################################################################
#CHANGE ALL PATHS ACCORDINGLY

#For pre-cleanup, use the following block of code for the path to set (and this would depend on your directory setup as well):
#'~/BaseDataPath/Data/HUMLabelData/A1_HUMLabelData_CleanupPipeline/A1_EAFFiles/'
#For post-clean up, the path to set is (this would also depend on your directory set up):
#~/BaseDataPath/Data/HUMLabelData/A1_HUMLabelData_CleanupPipeline/A3_EditedEafFiles/
  setwd('~/BaseDataPath/Data/HUMLabelData/A1_HUMLabelData_CleanupPipeline/A1_EAFFiles/')

#source all user-defined functions; CHANGE PATH ACCORDINGLY
  source('~/BaseCodePath/CodeForGitHub/A2_HUMLabelDataCleanUp/EafParsingFunctions.R')

#Note that this script is used to get parsed .csv files from .eaf files before and after clean-up. 
#This string is sort of the switch we use to go between both cases
CleanUpStatus = 'PreCleanUp'               #CHANGE TO 'PostCleanUp' or 'PreCleanUp' AS NEEDED
################################################################################################################################################################################################################################

CurrPath = getwd() #get current path
EafDir <- dir(CurrPath, pattern = ".eaf") #dir .eaf files

if (strcmp(CleanUpStatus,'PreCleanUp')){
  DestinationPath = '~/BaseDataPath/Data/HUMLabelData/A1_HUMLabelData_CleanupPipeline/A2_ParsedEafFilesFromR_PreCleanUp/'
  StrToRemoveToGetEafFnRoot = '_EditedMay2023.eaf' #change according to file name. The idea is to get the  file name root (eg. 0009_000603)
  StrToAddForCsvFn = '_PreCleanUp.csv' #change according to how output file name is expected
  SinkFileName = '~/BaseDataPath/Data/HUMLabelData/A1_HUMLabelData_CleanupPipeline/SummaryCsvAndTxtFiles/PreCleanUp_EafFileMissingTiersOtherGeneralErrorSummary.txt'
} else if (strcmp(CleanUpStatus,'PostCleanUp')){
  DestinationPath = '~/BaseDataPath/Data/HUMLabelData/A1_HUMLabelData_CleanupPipeline/A4_ParsedEafFilesFromR_PostCleanUp/'
  StrToRemoveToGetEafFnRoot = '.eaf' #change according to file name. The idea is to get the  file name root (eg. 0009_000603)
  StrToAddForCsvFn = '.csv' #change according to how output file name is expected
  SinkFileName = '~/BaseDataPath/Data/HUMLabelData/A1_HUMLabelData_CleanupPipeline/SummaryCsvAndTxtFiles/PostCleanUp_EafFileMissingTiersOtherGeneralErrorSummary.txt'
}

#start writing to o/p file (flags for if a certain tier doesn't exist in a file or if there aren't the same number of 
#annotations, annotation ids, start time refs, and end time refs within each tier we look at in a file)
sink(SinkFileName) #open sink file #any console o/p between the two calls of sink will go into the file

#go through files dir-d
for (i in 1:numel(EafDir)){ #
  
  EafFilename = EafDir[i] #set EafFilename variable as eaf file name (for reasons I do not quite understand, the actual file name
  #has to be stored as the 'EafFilename' variable to be passed on to the function, presumably because the input
  #for the function is a variable names EafFilename? I thought this could be a placeholder for a string but apparently not?)
  #Key tiers are : 'Infant Voc Type', 'Adult Utterance Dir' (because some files only have this much of the string),
  #'Adult Ortho' (for the orthograohic transcription tier; some files only have 'Adult Orthographic' in this tier label)
  
  GetParsedCsvFilesFromEaf(EafFilename,DestinationPath,StrToRemoveToGetEafFnRoot,StrToAddForCsvFn)
}

sink() #close sink






