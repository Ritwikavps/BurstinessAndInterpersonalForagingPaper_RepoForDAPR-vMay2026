#Functions used to extract infant age from .its files and write to a .csv file
########################################################################################################################################################################
#Function 1: Gets Infant DOB; Input is the name of the .its file
########################################################################################################################################################################
GetInfantDob <- function(ItsFileName){ 
  
  #First, establish a connection (which is an interface to the file) to the desires .eaf file
  myCon <- file(description = ItsFilename, open="r", blocking = TRUE) 
 
  repeat{ #Repeat till line is the empty vector or till DoB is found
    myLine <- str_trim(readLines(myCon, n = 1)) # Read one line from the connection.
    
    if (str_contains(myLine,'ChildInfo dob=')) {  #Find target string corresponding to Dob info and extract Dob
      DoB <- gsub(pattern='".*', replacement='', x = gsub(pattern='.*ChildInfo dob="', replacement='', x = myLine)) #extract DOB (yyyy-mm-dd)
      break 
    }
    
    if (identical(myLine, character(0))) { # If the line is empty, exit.
      DoB <- '' #If, for some reason, the DOB target string doesnt exist
      break
    } 
    #print(myLine) # Otherwise, print and repeat next iteration.
  }
  
  #Explicitly opened connection needs to be explicitly closed.
  close(myCon); rm(myCon)
  return(DoB)
}

########################################################################################################################################################################
#Function 1: Gets recording date; Input is the name of the .its file
########################################################################################################################################################################
GetRecDate <- function(ItsFileName){ 
  
  #First, establish a connection (which is an interface to the file) to the desires .eaf file
  myCon <- file(description = ItsFilename, open="r", blocking = TRUE) 
  
  repeat{ #Repeat till line is the empty vector or till the recording date is obtained
    myLine <- str_trim(readLines(myCon, n = 1)) # Read one line from the connection.
    
    if (str_contains(myLine,'startClockTime="')) {  #Find target string corresponding to recoding date info and extract
      RecDate <- gsub(pattern='T.*', replacement='', x = gsub(pattern='.*startClockTime="', replacement='', x = myLine))
      break
    }
    
    if (identical(myLine, character(0))) {  # If the line is empty, exit.
      RecDate <- '' #if, for some reason, the recording date target string doesnt exist
      break
    }
    #print(myLine) # Otherwise, print and repeat next iteration.
  }
  
  #Explicitly opened connection needs to be explicitly closed.
  close(myCon); rm(myCon)
  return(RecDate)
}

########################################################################################################################################################################
#Function 3: Get infant age at time of recording in days; Input is the name of the .its file
########################################################################################################################################################################
GetInfAge <- function(ItsFilename){
  
  DoB <- GetInfantDob(ItsFilename) #Get date of birth
  RecDate <- GetRecDate(ItsFilename) #Get recording date
  InfantAge <- round(as.numeric(difftime(RecDate,DoB,units = 'days'))) #Get the difference, convert to a number, and round
  return(InfantAge)
}

########################################################################################################################################################################
#Function 4: Get infant ID from metadatafile; Inputs are the .csv file with .its file names and infant ID (ItsFileTab); and the name of the .its file (ItsFilename)
########################################################################################################################################################################
GetInfantID <- function(ItsFileTab,ItsFilename){
  
  FileNameRoot <- gsub('.its','',ItsFilename) #Get filename root. 
  TargetRow <- filter(ItsFileTab, FNRoot == FileNameRoot) #Get corresponding row from metadata file
  InfID <- TargetRow$InfantID #get infant ID
  return(InfID)
}
