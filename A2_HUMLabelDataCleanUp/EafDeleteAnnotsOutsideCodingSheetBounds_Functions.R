#%@author info, June 2022
#This script contains functions used to get line nums that need to be deleted, corresponding to annotations that are outside the coding spreadsheet bounds
#Required libraries: sjmisc, stringr, pracma
#also make sure to be in the correct directory

########################################################################################################################################################################
#Function 1: Gets sub-table corresponding to given file name, with line nums for annotation, annotation id, start and end time ref as well as filename:
#gets annotation line num, start and end time ref line num, and annotation id line num, as well as filename, corresponding to annotations
#outside codings preadsheet bds for a given file name
########################################################################################################################################################################
GetAnnotationLineNumOutsideBds <- function(EafFileNameRoot,AnnotOutsideCodingSpreadsheetBds_df){

  ToDeleteLineNumsDetails_df = data.frame(matrix(ncol = 5, nrow = 0))#initialise output df
  colnames(ToDeleteLineNumsDetails_df) <- colnames(AnnotOutsideCodingSpreadsheetBds_df) #assign same colname sto output df as input df

  for (i in 1:numel(AnnotOutsideCodingSpreadsheetBds_df$EafFname)){ #go through file name vector
    if (strcmp(AnnotOutsideCodingSpreadsheetBds_df$EafFname[i],EafFileNameRoot)){ #if filename is the same as the target filename
      #append row to output table
      ToDeleteLineNumsDetails_df = rbind(ToDeleteLineNumsDetails_df,AnnotOutsideCodingSpreadsheetBds_df[i,])
    }
  }
  return(ToDeleteLineNumsDetails_df)
}

########################################################################################################################################################################
#Function 2: Gets line numbers that need to be deleted given the subtable that is the output of GetAnnotationLineNumOutsideBds:
#gets a list containing line numbers that need to be deleted within the annotation block in the eaf file, corresponding to annotations
#that are outside the coding spreadsheet bounds
########################################################################################################################################################################
GetLineNumsToDelete <- function(EafFileName,ToDeleteLineNumsDetails_df){
  
  #first, go through the input table, and get line nums that need to be deleted.
  #To do this, we note that each annotation sub-block starts one line before the line with the annotation id, and ends 2 lines after the annotation line
  #That is, annotation sub-block start line = annotation id line - 1 (characterised by <ANNOTATION> ); 
  #, and annotation sub-block end line = annotation line + 2 (characterised by </ANNOTATION>)
  
  DimsOf_ToDeleteLineNumsDetails_df = dim(ToDeleteLineNumsDetails_df) #check for if the ToDeleteLineNumsDetails_df is empty
  
  if (DimsOf_ToDeleteLineNumsDetails_df[1]*DimsOf_ToDeleteLineNumsDetails_df[2] == 0){ #if df is empty
    LineNumsToDelete = c()
  } else {
    #First, read and store file
    myCon = file(description = EafFileName, open="r", blocking = TRUE) #establish connection
    
    #initialise counter variable as well as vectors to store info in
    LineVec <- c()
    LineNum = 0
    
    repeat{ #repeat till line is the empty vector
      myLine = str_trim(readLines(myCon, n = 1)) # Read one line from the connection.
      
      if(identical(myLine, character(0))){
        break
      } # If the line is empty, exit.
      #print(myLine) # Otherwise, print and repeat next iteration.
      
      LineNum = LineNum + 1
      LineVec[LineNum] = myLine
    }
    
    #Explicitly opened connection needs to be explicitly closed.
    close(myCon)
    rm(myCon)
    
    #Now, identify lines to delete
    LineNumsToDelete = c() #initialise vector to store Line to delete
    
    for (i in 1:numel(ToDeleteLineNumsDetails_df$AnnotIdLineNum)){ #go through each row of table
      
##################################################################################################################################################################################
      #These may change as the eaf files go through multiple cleaning rounds or just being opened in ELAN on different systems, so please edit 
      #accordingly. There are checks for this in the if block below
      AnnotBlockStartLine = ToDeleteLineNumsDetails_df$AnnotIdLineNum[i] - 3 #identify start and end line nms of annotation sub-blkock
      AnnotBlockEndLine = ToDeleteLineNumsDetails_df$AnnotationLineNum[i] + 2
      
      #check if start and end lines are correct
      if ((str_contains(LineVec[AnnotBlockStartLine],'<ANNOTATION>')) && (str_contains(LineVec[AnnotBlockEndLine],'</ANNOTATION>'))){
        LineNumsToDelete = append(LineNumsToDelete,AnnotBlockStartLine:AnnotBlockEndLine)
      } else { #if start and end lines have not been correctly id'd, print the id'd lines
        print(EafFileName)
        print(LineVec[AnnotBlockStartLine])
        print(LineVec[AnnotBlockEndLine])
      }
##################################################################################################################################################################################
    }
  }
  return(LineNumsToDelete)
}
  
  
