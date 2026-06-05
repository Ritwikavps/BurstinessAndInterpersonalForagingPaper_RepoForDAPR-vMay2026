#Fn 1: #This function takes the list of files to run the analyses on, runs the analyses to get residuals based on previous step size ctrl at the recording day level, 
#and writes output into a single file. Note that this the master function that runs the analyses to get residuals, and all inputs for subsequent functions are 
#specified here

#Inputs to this function are - the list of working directory paths (WorkingDir)
#- the string pattern to match to get the required files (FilePattern)
#- the list of data types we are dealing with (eg. LENA, LENA5min, Hum) (DataType)
#- the path to which output should be written (WriteOpPath)
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
WriteResidsToFile_RecLvl <- function(WorkingDir,FilePattern,DataType,WriteOpPath){
  
  FinalOpTab <- NULL #Initialise final output tibble
  
  for (i in 1:numel(WorkingDir)){ #go through list of working directories (indexed in the same order as DataType): for all four data types: LENA day-long, 
    #human-listener labelled 5 min (with all adult vocs), human-listener labelled 5 min (only child-dir adult vocs), and LENA 5 min
    
    setwd(WorkingDir[i]) #set working directory
    FilesToLoad <- list.files(path = getwd(),pattern = FilePattern)  #get list of required files
    
    for (i_file in FilesToLoad){ #go through list of files 
      
      DataTab <- read_csv(i_file); 
      RespTypeStr <- gsub('.*_','',gsub('_IviOnly.csv','',gsub('CurrPrevStSize_','',i_file))) #get the response_to_speaker string from the file name
      
      #Get output table for the read in data table (each data table read in has a unique response_to_speaker and data_type combo)
      TempOpTab <- GetResidsOpTabFor_uDataTypeAndSpkr(DataTab) 
      TempOpTab$ResponseType <- rep(RespTypeStr,nrow(TempOpTab)); TempOpTab$DataType <- rep(DataType[i],nrow(TempOpTab)) #add DataType and ResponseType columns
      FinalOpTab <- bind_rows(FinalOpTab,TempOpTab) #append to final output table
    }
  }
  
  Fname <- strcat('PrevStSizeResids_VarsScaleLog_RecDayLvl_IviOnly','.csv') #get file name to save
  setwd(WriteOpPath); write.csv(FinalOpTab, file = Fname,row.names=FALSE) #write file
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Fn 2: This function takes in the input data tab (each input tab has all the current and previous IVIs and response info--for all response windows--for a given combo
#of data type (eg. LENA daylong, LENA 5 min, etc) and response-to-speaker type (ANRespToCHNSP, CHNSPRespToAN)), subsets for each recording day (by filtering for
#unique combos of infant ID and age in months), does the prev. step size control analysis (linear model, since there are no random effects because all data points 
#are from the same infant at the same age), and appends the residuals to the output table (see GetPrevStCtrlResids_RecLvl below for more details)
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GetResidsOpTabFor_uDataTypeAndSpkr <- function(InputTab){
  
  u_Age <- c(3,6,9,18); u_ID <- unique(InputTab$InfantID) #get unique ages and IDs (note we are only looking at ages 3, 6, 9, and 18 months)
  OpTab <- NULL #initialise output table
  
  for (i_age in u_Age){
    for (i_ID in u_ID){
      
      SubTab <- filter(InputTab, AgeMonths == i_age & InfantID == i_ID) #subset by filtering for 18 months
      if (nrow(SubTab) > 1){ #can only do a linear model if there are at least 2 points
        OpSubTab <- GetResids_RecLvl(SubTab)#get table with residuals
        OpTab <- bind_rows(OpTab,OpSubTab) #append to output table
      }
    }
  }
  return(OpTab)
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Fn 3: This function takes in the subsetted table (subsetted for a given infant ID and infant age), does the previous step size control test, and outputs the following 
#(as a tibble): CurrIVI and PrevIVI, CurrIVI and PrevIVI after log transform and scaling, CurrIVI residuals and scaled residuals from prev. step size control test,
#age and ID info, and response data
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GetResids_RecLvl <- function(InputTab){
  
  attach(InputTab)
  
  CurrIVI_Trans <- scale(log10(CurrIVI + (10^-10))); PrevIVI_Trans <- scale(log10(PrevIVI + (10^-10))) #get log transform-d and scaled versions
  
  LmMdl_PrevSt <- lm(CurrIVI_Trans ~ PrevIVI_Trans,na.action=na.exclude) #do prev IVI lmer (after excluding any NA values)
  ResidVar <- resid(LmMdl_PrevSt); ResidVar_Scaled <- scale(ResidVar) #get residuals and scaled residuals
  
  TabToAppendTo <- select(InputTab,!AgeDays) #remove AgeDays column from input table
  TabwOpVars <- tibble(CurrIVI_Trans,PrevIVI_Trans,ResidVar,ResidVar_Scaled) #get table with residuals and transformed IVIs
  OpTab <- bind_cols(TabToAppendTo,TabwOpVars) #append to input table
  
  detach(InputTab)
  return(OpTab)
}


