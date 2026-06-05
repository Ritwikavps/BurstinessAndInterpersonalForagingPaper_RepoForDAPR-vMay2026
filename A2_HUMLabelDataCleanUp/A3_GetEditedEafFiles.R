#%@author info
#June 2022
#This script (and supporting functions) go through every .eaf file in a given folder and does the following:
# 1) Remove annotations outside of the coding spreadsheet bounds
# 2) Check annotations (currently only Infant Voc Type and Adult Utt Dir tier),
#id annotations, checks if annotations have simple errros (lower case annotations instead of upper case, 
#additional white space or tab characters or non-alphabet character, or multiple instances of the same annotation 
#, or a combo of these), edits these simple errors, and 
#3) Edit non-standard tier names ito standaard tier names where applicable
# 3) write a new .eaf file with the edits.

#load required librarues
library(pracma) #lots fo basic functions
library(stringr)
library(sjmisc)

################################################################################################################################################################################################################################
#CHANGE ALL PATHS ACCORDINGLY

#set working directory
setwd('~/BaseDataPath/Data/HUMLabelData/A1_HUMLabelData_CleanupPipeline/A1_EAFFiles/')

#source necessary fns
source('~/BaseCodePath/CodeForGitHub/A2_HUMLabelDataCleanUp/EafSimpleErrorEditingFunctions.R')
source('~/BaseCodePath/CodeForGitHub/A2_HUMLabelDataCleanUp/EafDeleteAnnotsOutsideCodingSheetBounds_Functions.R')
source('~/BaseCodePath/CodeForGitHub/A2_HUMLabelDataCleanUp/EafTierNameEditingFunctions.R')

#Read csv file with info about annotations outside of coding spreadsheet bounds
AnnotOutsideCodingSpreadsheetBds_df <- read.csv('~/BaseDataPath/Data/HUMLabelData/A1_HUMLabelData_CleanupPipeline/SummaryCsvAndTxtFiles/PreCleanUpAnnotsOutsideCodingSheetBds.csv',header = TRUE,quote = "")[,c('StartTimeLineNum','EndTimeLineNum','AnnotIdLineNum','AnnotationLineNum','EafFname')]
################################################################################################################################################################################################################################

CurrPath = getwd() #get current path
aa <- dir(CurrPath, pattern = ".eaf") #dir .eaf files

#We need to address three things: deleting annotations outside coding sheet bounds, editing simple errors in annotations, and editing non-standard tier names to the standard versions
#For the first, we will generate a list of line nums to be deleted -- basically, the line nums corresponding to the annotation sub-block, from <ANNOTATION> to </ANNOTATION>
#To do this, we will first look at the summary csv file (from MATLAB), find start and end of annotation sub-block for each annotation in the spreadsheet
#Then, as we go through the .eaf file line by line, we will check, at each line, if it needs to be deleted or not
#If yes, we will not write it into the new file
#Note that we don't need to delete the time refs at the start of the eaf file, even if they refere to an annotation outside the spreadsheet bounds
#To edit non-standard tier names, we simply check if a line is the start of a tier, check against the lost of standard tier names and edit accordingly
#For the last part of editing simple errors in annotations, we do the following:
#First, we use a function that checks if it is an annotation line
#If yes, then we use a function that finds which tier it is in
#Then we use a function that checks if the annotation needs editing
#If yes, we use a function that provides the edited annotation

#go through files dir-d
for (i in 1:numel(aa)){                                 #
  
  EafFileName = aa[i] #get file name
  
  #First, get list of line nums to be deleted
  ################################################################################################################################################################################################################################
  #There maybe prefixes before the '.eaf' below, eg. 0009_000401_xyz.eaf. In this case, the first argument for gsub would be '_xyz.eaf'. Please 
  #change accordingly, below
  EafFileNameRoot = gsub('.eaf','',EafFileName) #get file name root
  ToDeleteLineNumsDetails_df = GetAnnotationLineNumOutsideBds(EafFileNameRoot,AnnotOutsideCodingSpreadsheetBds_df) #get sub-table with details of annotations outside coding bouds for given file
  ################################################################################################################################################################################################################################
  
  #check for if ToDeleteLineNumsDetails_df is empty
  DimsOf_ToDeleteLineNumsDetails_df = dim(ToDeleteLineNumsDetails_df)
  if (DimsOf_ToDeleteLineNumsDetails_df[1]*DimsOf_ToDeleteLineNumsDetails_df[2] == 0){ #if df is empty
    LineNumsToDelete = c()
  } else {
    LineNumsToDelete = GetLineNumsToDelete(EafFileName,ToDeleteLineNumsDetails_df)
  }
  
  #Get tier information: list of tiers, start and ending line numbers of each tier
  TierList_df = GetTierListInfo(EafFileName)
  
  ################################################################################################################################################################################################################################
  #CHANGE STRING SUFFIXES FOR FILENAME AS NEEDED
  #initialise list to save text as well as filename to save
  FN_ToSave = strcat(EafFileNameRoot,'_Edited.eaf')
  #CHANGE ALL PATHS ACCORDINGLY
  FN_AndLocationToSave = strcat('~/BaseDataPath/Data/HUMLabelData/A1_HUMLabelData_CleanupPipeline/A3_EditedEafFiles/',FN_ToSave)
  ################################################################################################################################################################################################################################
  TextToWrite = c()
  EditsMadeCtr = 0
  
  #Now, we will start with the editing process 
  myEditCon = file(description = EafFileName, open="r", blocking = TRUE) #establish connection
  
  LineNum = 0 #initialise line num
  
  repeat{ #repeat till line is the empty vector
    myLine = readLines(myEditCon, n = 1) # Read one line from the connection.
    
    if(identical(myLine, character(0))){
      break
    } # If the line is empty, exit.
    #print(myLine) # Otherwise, print and repeat next iteration.
    
    LineNum = LineNum + 1
    
    if (LineNum %in% LineNumsToDelete){ #first check if line is a line to be deleted, if yes, update editsmade Ctr
      
      EditsMadeCtr = EditsMadeCtr + 1 #this is an indicator to check if an edited file needs to be saved. 
      #Since this is a line to be deleted, we don't have to do anhything further, we skip appending this line to the new text to write and move on
      
    } else if (!(LineNum %in% LineNumsToDelete)){ #Next check if current line number is not in the line number to delete list; if true, proceed
      
      IsAnnot = CheckIfAnnotLine(myLine) #check if line contains annotation
      TierFlag = CheckIfTierLine(myLine) #check if this line contains a tier name
      
      if (IsAnnot){ #if it is a line with annotation, find which tier the annotation is in
        AnnotTier = GetAnnotationTier(LineNum,TierList_df$TierIdVec,TierList_df$TierStartLineNum,TierList_df$TierEndLineNum)
        
        #if it is inf voc or adult utt dir tier, get the annotation
        if ((str_contains(AnnotTier,'Infant Voc Type',ignore.case = TRUE)) || (str_contains(AnnotTier,'Adult Utterance Dir',ignore.case = TRUE))){
          
          Annotation = gsub('>',"",gsub('</ANNOTATION_VALUE>',"",gsub('<ANNOTATION_VALUE',"",str_trim(myLine)))) #Get annotation
          
          #Check if annotation needs editing; first assign AllowedAnnot
          if (str_contains(AnnotTier,'Infant Voc Type',ignore.case = TRUE)){
            AllowedAnnot = c('X','R','L','C')
          } else if (str_contains(AnnotTier,'Adult Utterance Dir',ignore.case = TRUE)) {
            AllowedAnnot = c('T','U','N')
          }
          
          NeedsEdit = CheckAnnotationForSimpleError(Annotation,AllowedAnnot)
          
          if (NeedsEdit){ #if annotation needs editing, get edited annotation
            Annotation = GetEditedAnnotation(Annotation)
            print(myLine) #ONLY FOR DEBUGGING
            LineSplit_v1 = strsplit(myLine,'<ANNOTATION_VALUE')##do the splitting of the line; this should give a list with 
            #white space and '>X</ANNOTATION_VALUE>' (or if the original line is <ANNOTATION_VALUE/>X</ANNOTATION_VALUE>),
            #the second element or the list would be />X</ANNOTATION_VALUE>
            #We can reconstitute this as LineSplit_v1(1)+'<ANNOTATION_VALUE'+LineSplit_v1(2)
            LineSplit_v2 = strsplit(LineSplit_v1[[1]][2],'</ANNOTATION_VALUE>') #this gives us '>X' or '/>X'.
            #We have already extracted the annotation and edited it
            #Now, we can reconstitute the line as LineSplit_v1(1)+<ANNOTATION_VALUE+>+Annotation+</ANNOTATION_VALUE>
            myLine = paste(LineSplit_v1[[1]][1],'<ANNOTATION_VALUE','>',Annotation,'</ANNOTATION_VALUE>',sep = '',collapse = NULL)
            
            EditsMadeCtr = EditsMadeCtr + 1
            print(myLine) #ONLY FOR DEBUGGING
          }
        }
      } else if (TierFlag){ #if this *is* a tier name line, check if the tier name requires editing
        
        TierNameEditFlag = TierLabelEditCheck(myLine)
        
        if (TierNameEditFlag){ #if yes, edit
          
          print(EafFileName) #The print statement are just here to show the edits as they are being made
          print(myLine)
          
          myLine = EditTierName(myLine)
          EditsMadeCtr = EditsMadeCtr + 1
          
          print(myLine)
        }
      } else if (TierFlag && IsAnnot){
        stop('Line flags TRUE for annotation *and* start of a tier! Check file!')
      }
      
      #WRITE NEW LINE
      TextToWrite = append(TextToWrite,myLine)
    }
  }
  
  #Explicitly opened connection needs to be explicitly closed.
  close(myEditCon)
  rm(myEditCon)
  
  closeAllConnections() #close all connections, just to be safe
  
  if (EditsMadeCtr > 0){ #If tier names have been edites
    writeLines(TextToWrite, FN_AndLocationToSave) 
    print(EafFileName) #DEBUGGING ONLY
  }else{
    file.copy(EafFileName,FN_AndLocationToSave) #if not, simply copy the old file to the new location with the new name
  }
  
  closeAllConnections() #close all connections, just to be safe
}