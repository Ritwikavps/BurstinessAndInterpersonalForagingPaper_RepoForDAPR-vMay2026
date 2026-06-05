#%@author info
#Jul 2024
#This script (and associated function(s)) checks and flags for .eaf files whose file names don't match the audio file names. Names of any flagged eaf files are printed
#as output

#load required librarues
library(pracma); library(sjmisc); library(tidyverse)

################################################################################################################################################################################################################################
#CHANGE ALL PATHS AND STRINGS ACCORDINGLY

#set directory with edited .eaf files. This is the path with the edited eaf files (as of Jul 20, 2024, this is the 'Edited May 2023' folder that is post-clean-up by 
#JM and RVPS; ref to the clean-up README on Box for this)
PathwEditedEafFiles <- '~/BaseDataPath/Data/HUMLabelData/A2_HUMLabelData_PostCleanUp/A1_CleanedUpEafFiles/'
StrToRemove <- '_EditedMay2023.eaf' #this is the string to remove from the eaf file names to get the file name roots
#This is the csv file with old and new file names
Csv_wOldFnames <- '~/BaseDataPath/Data/MetadataFiles/ItsFileDetailsWOldFN.csv'
#This is the directory with the original eaf files (to check for whether the correct audio file was opened or not); Note that the 'IVFCR' at the end is the prefix
#for the target directories, which are of the form 'IVFCR<InfantID>'
HumAnnotOrigDir = '~/BaseCloudPath/'
################################################################################################################################################################################################################################

EditedEafFileList <- dir(PathwEditedEafFiles, pattern = ".eaf") #get vector of .eaf files
EditedEafFnRoots <- gsub(StrToRemove,'',EditedEafFileList) #remove the necessary string from the vector of eaf file names obtained
Tab_wOldFnRoots <- read_csv(Csv_wOldFnames) #read in the csv file with the old and new file names; This is because we renamed the .eaf, .its, and .wav files to a 
#more standardised format as part of the pre-processing; hwoever, when the human-listener annotations were done, thsi re-naming had not yet been done. So, we need 
#to match the new file names to old file names
Tab_wOnlyEafFnRoot <- Tab_wOldFnRoots[Tab_wOldFnRoots$FNRoot %in% EditedEafFnRoots,] #subset to get ONLY the filenames corresponding to the eaf files; we
#are using logical indexing here

for (i in 1:numel(Tab_wOnlyEafFnRoot$FNRoot)){ #go through the list of eaf files
  if (Tab_wOnlyEafFnRoot$InfantID[i] =='384B'){ #the directory with the files for infant 384B has a '-' in the name of the directory, so make that edit to path
    #correctly
    InfantIdStr <- '384-B'
  } else {
    InfantIdStr <- Tab_wOnlyEafFnRoot$InfantID[i]
  }
  setwd(str_c(HumAnnotOrigDir,InfantIdStr,'/')) #set the required directory in which the .wav files are for the giev eaf file
  #Note that str_c concatenates strings
  OldFn_i = str_c(Tab_wOnlyEafFnRoot$OldFNRoot[i],'.eaf') #get the old file name
  
  CurrConn = file(description = OldFn_i,open="r",blocking = TRUE) #open connetion to file so we can read it line by line
  repeat{ #repeat till myLine is the empty vector
    myLine = str_trim(readLines(CurrConn, n = 1)) # Read one line from the connection.
    if(identical(myLine, character(0))){ #if we are at the last line (ie, line is empty) 
      break
    }
    
    if (str_contains(myLine,'.wav')){ #if the line contains .wav, then this has the wave file name
      AudioFname = gsub('.*/','',gsub('.wav.*','',gsub('.*IVFCR','',myLine))) #get the audio file name by serially removing sub-strings
      break #once we get the audio file name, break out of the loop
    }
  }

  close(CurrConn); rm(CurrConn) #Explicitly opened connection needs to be explicitly closed.
  
  if (!strcmp(AudioFname,Tab_wOnlyEafFnRoot$OldFNRoot[i])){ #if pre-renaming eaf file name and opened audio file don't match, print message
    fprintf('.wav and .eaf filenames do not match for renamed .eaf file %s \n',Tab_wOnlyEafFnRoot$FNRoot[i]) 
    fprintf('The old .eaf file name is %s and the opened audio file is %s',Tab_wOnlyEafFnRoot$OldFNRoot[i],AudioFname)
  }
}
