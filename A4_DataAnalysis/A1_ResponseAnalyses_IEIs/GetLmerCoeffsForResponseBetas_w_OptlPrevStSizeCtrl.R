#Fn 1: #This function takes the list of files to run the analyses on, runs the following two functions, and writes output. Note that this the master function that
#runs the response effect analyses, and all inputs for subsequent functions are specified here

#Inputs to this function are - the list of working directory paths (WorkingDir)
#- the string pattern to match to get the required files (FilePattern)
#- the list of data types we are dealing with (eg. LENA, LENA5min, Hum) (DataType)
#- the path to which output should be written (WriteOpPath)
#- the string identifying whether we are running the stats with or without previous step size control
#- the desired confidence level to compute confidence interval in the form of a percent value. That is, for 95% confidence intervals, CILvl = 95 (correponding to 
# a p-value alpha threshold = 0.05) and so on and so forth (CILvl)

#Stats results for with (or without, as applicable; specified by the PrevStSiCtrlOrNo input) previous IVI control is done for all four data types: LENA day-long, 
#human-listener labelled 5 min (with all adult vocs), human-listener labelled 5 min (only child-dir adult vocs), and LENA 5 min, and written into a single output file.
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
WriteOpToFile_RespEffBetas <- function(WorkingDir,FilePattern,DataType,WriteOpPath,PrevStSiCtrlorNo,CILvl){
  
  FinalOpTab <- NULL #Initialise final output tibble
  CIStr <- gsub('\\.','_',strcat(as.character(CILvl),'prc')) #convert the CILvl to a string, add 'prc' to signify percent, then sub the decimal point ('.')--if it
   #is present in the CILvl provided--with underscore ('_') (for easier variable naming that translates well across R and MATLAB). Now, we can use this string to 
   #add to final file name, so we know what teh CI lvl is for the results table
  
  CILvl <- CILvl/100 #convert to <percent/100> such that a conf lvl of 99.9 is expressed as 0.999, which is the required R syntax
  
  for (i in 1:numel(WorkingDir)){ #go through list of working directories (indexed in the same order as DataType): for all four data types: LENA day-long, 
    #human-listener labelled 5 min (with all adult vocs), human-listener labelled 5 min (only child-dir adult vocs), and LENA 5 min
    
    setwd(WorkingDir[i]) #set working directory
    FilesToLoad <- list.files(path = getwd(),pattern = FilePattern)  #get list of required files
    
    for (RespType in c('ANRespToCHNSP','CHNSPRespToAN')){ #go through the response-to-speaker types
      if (strcmp(PrevStSiCtrlorNo,'wCtrl')){ #run appropriate function depending on whether prev st size control is being implemented or not
        StatsOp_Temp <- GetRespEff_w_PrevStSiCtrl_IVI(FilesToLoad,RespType,DataType[i],CILvl)
      } else if (strcmp(PrevStSiCtrlorNo,'woCtrl')){
        StatsOp_Temp <- GetRespEffNoPrevStSiCtrl_IVI(FilesToLoad,RespType,DataType[i],CILvl)
      }
      StatsOp_Temp$ResponseType <- rep(RespType,nrow(StatsOp_Temp)) #add response type column
      StatsOp_Temp$DataType <- rep(DataType[i],nrow(StatsOp_Temp)) #add DataType column
      FinalOpTab <- bind_rows(FinalOpTab,StatsOp_Temp) #append to final output table
    }
  }
  
  if (strcmp(PrevStSiCtrlorNo,'wCtrl')){ #get output filename appropraitely
    Fname <- strcat(strcat('RespEff_W_PrevStSizCtrl_VarsScaleLog_CorpusLvl_IviOnly_CI',CIStr),'.csv') #get file names to save
  } else if (strcmp(PrevStSiCtrlorNo,'woCtrl')){
    Fname <- strcat(strcat('RespEff_NoPrevStSizCtrl_VarsScaleLog_CorpusLvl_IviOnly_CI',CIStr),'.csv')
  }
  
  setwd(WriteOpPath)
  write.csv(FinalOpTab, file = Fname,row.names=FALSE) #write file
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Fns 2 and 3: These functions take the list of files to run analyses on, and assigns the appropriate function (for LENA daylong or validation data) to get the output tibble, With ando
#WITHOUT  the previous step size control protocol.
#Inputs: - FilesToLoad: the list of files in the directory 
# - RespType: A string of the form <Responder>RespTo<Spkr> that identifies the speaker type and the responder type
# - DataType: a string identifying the labelling method, i.e.,LENA, LENA5min, or Hum
# - CILvl: the desired confidence level to compute confidence interval in the form of <percent/100>. That is, for 95% confidence intervals, CILvl = 0.95 
 #(correponding to a p-value alpha threshold = 0.05) and so on and so forth. NOTE THAT in the master function WriteOpToFile_RespEffBetas, CILvl is specified
 #as a percent value (i.e., 95 instead 0.95, in the example given here), and that value gets converted to <percent/100> before passing on to these functions
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GetRespEff_w_PrevStSiCtrl_IVI <- function(FilesToLoad,RespType,DataType,CILvl){
  if (strcmp('LENA',DataType)){ #check DataType string
    OpTab <- GetRespEff_IVI_w_PrevStSiCtrl_LENA(FilesToLoad,RespType,CILvl) #assign relevant function
  }else if (strcmp('LENA5min',DataType) || strcmp('Hum-AllAd',DataType) || strcmp('HumChildDirAdOnly',DataType)){
    OpTab <- GetRespEff_IVI_w_PrevStSiCtrl_ValData(FilesToLoad,RespType,CILvl)
  } else {
    stop('Data type not one of the following: LENA, LENA5min, Hum-AllAd, HumChildDirAdOnly')
  }
  return(OpTab)
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GetRespEffNoPrevStSiCtrl_IVI <- function(FilesToLoad,RespType,DataType,CILvl){
  if (strcmp('LENA',DataType)){ #Check DataType string, assign relevenat function
    OpTab <- GetRespEff_IVI_NoPrevStSiCtrl_LENA(FilesToLoad,RespType,CILvl)
  }else if (strcmp('LENA5min',DataType) || strcmp('Hum-AllAd',DataType) || strcmp('HumChildDirAdOnly',DataType)){
    OpTab <- GetRespEff_IVI_NoPrevStSiCtrl_ValData(FilesToLoad,RespType,CILvl)
  } else {
    stop('Data type not one of the following: LENA, LENA5min, Hum-AllAd, HumChildDirAdOnly')
  }
  return(OpTab)
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Fn 4: #This function takes the list of files in the directory (FilesToLoad) as well as a string identifying the target speaker and responder (RespToSpkr;
#eg. ANRespToCHNSP), performs the two-step response effect analysis controlling for the effect of any intrinsic vocalisation pattern of the 
#target speaker, and outputs the results of stastitical analyses as a tibble. Note that here, we are only doing the analyses on IVIs.
#Here, we implement two steps: get the previous step size beta values, and then, response effect beta values based on residuals of the Current IVI ~ Previous IVI analyses.
#Note that this is done in two steps because the CurrIVI ~ PrevIVI analyses are carried out on all non-NaN steps, but the response analyses are only done on steps
#associated with non-NA responses.
#The third input is CILvl, which is the desired confidence level to compute confidence interval in the form of <percent/100>. That is, for 95% confidence intervals, 
#CILvl = 0.95 (correponding to a p-value alpha threshold = 0.05) and so on and so forth. NOTE THAT in the master function WriteOpToFile_RespEffBetas, CILvl is 
#specified as a percent value (i.e., 95 instead 0.95, in the example given here), and that value gets converted to <percent/100> before passing on to these functions.
#Note that this function implements the protocol for LENA day-long data.
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GetRespEff_IVI_w_PrevStSiCtrl_LENA <- function(FilesToLoad,RespToSpkr,CILvl){
  
  InfAge_Months <- c(); RespWin_Seconds <- c() #initialise vectors to iteratively store output in; #StepVar <- c(); 
  PrevSt_Beta <- c(); PrevStP <- c(); PrevStCI_Lwr <- c(); PrevStCI_Upper <- c()
  Response_Beta <- c(); ResponseP <- c(); ResponseCI_Lwr <- c(); ResponseCI_Upper <- c()
  Ctr <- 0; #initialise counter variable
  
  for (i in FilesToLoad){ #go through file list
    if (str_contains(i,RespToSpkr)){ #check if file name has the target string indicating speaker and responder types
      
      DataTab <- read_csv(i); attach(DataTab) #read table and attach
      RespWindowVals <- gsub('Response_','',colnames(DataTab)[1:11]) #get response window values: the first 11 cols of the data table is responses, 
      #for response windows 0.5, and 1 through 10 seconda, at 1 s increments. Picking these out and removing the 'Response_' string gives us just the numbers
      
      for (k in c(3, 6, 9, 18)){ #do analyses separately for different ages
        
        SubsetTab <- filter(DataTab, AgeMonths == k) #subset for age in months
        IDforAge_k <- as_factor(SubsetTab$InfantID); #get ID
        CurrVar <- log10(SubsetTab$CurrIVI + (10^-10)); PrevVar <- log10(SubsetTab$PrevIVI + (10^-10)) #log current and previous IVIs
        
        for (j in 1:numel(RespWindowVals)){ #Go through the different response windows
          
          Ctr <- Ctr + 1 #increment counter
          ResponseForAge_k <- SubsetTab[,j] #get j-th response vector for j-th response window value; Note that indexing this way makes it so that responseForAge_k is a tibble 
          #with one column, and the column name from SubsetTab is preserved
          
          #run just prev IVI model and get residuals
          LmerMdl_PrevSt <- lmer(scale(CurrVar) ~ (1|IDforAge_k) + scale(PrevVar),na.action=na.exclude) #exclude NA values of the input variables, if any, in the fit
          PrevStSummary <- summary(LmerMdl_PrevSt); PrevStCIs <- confint(LmerMdl_PrevSt,level = CILvl)
          ResidVar <- resid(LmerMdl_PrevSt)
          
          TabForLm <- tibble(ResidVar,ResponseForAge_k) #get table for linear model so we can subset only non-NaN responses
          colnames(TabForLm)[2] <- 'CurrRespVar' #rename the second column to a standard name as opposed to the preserved column name from SubsetTab
          LmSubsetTab <- filter(TabForLm,!is.nan(CurrRespVar)) #filter for non-NaN repsonse values ONLY
          ResponseForLm <- as_factor(LmSubsetTab$CurrRespVar) 
          
          #run response effect on residuals
          LmMdl_Resp <- lm(scale(LmSubsetTab$ResidVar) ~ ResponseForLm) #+ poly(Age,2,raw = TRUE) + poly(Age,2,raw = TRUE)*ResponseForLm)
          RespSummary <- summary(LmMdl_Resp); RespCIs <- confint(LmMdl_Resp,level = CILvl)
          
          #store results
          RespWin_Seconds[Ctr] <- as.numeric(RespWindowVals[j]); InfAge_Months[Ctr] <- k #StepVar[Ctr] <- gsub('Curr','',colnames(SubsetTab)[j]); 
          PrevSt_Beta[Ctr] <- PrevStSummary$coefficients[2,1] 
          PrevStP[Ctr] <- PrevStSummary$coefficients[2,5] 
          PrevStCI_Lwr[Ctr] <- PrevStCIs[4,1]
          PrevStCI_Upper[Ctr] <- PrevStCIs[4,2]
          
          Response_Beta[Ctr] <- RespSummary$coefficients[2,1] 
          ResponseP[Ctr] <- RespSummary$coefficients[2,4]
          ResponseCI_Lwr[Ctr] <- RespCIs[2,1]
          ResponseCI_Upper[Ctr] <- RespCIs[2,2]
        } 
      }
      detach(DataTab)
    }
  }
  
  OpTab <- tibble(RespWin_Seconds,InfAge_Months,
                  PrevSt_Beta,PrevStP,PrevStCI_Lwr,PrevStCI_Upper,
                  Response_Beta,ResponseP,ResponseCI_Lwr,ResponseCI_Upper)
  return(OpTab)
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Fn 5: #This function takes the list of files in the directory (FilesToLoad) as well as a string identifying the target speaker and responder (RespToSpkr;
#eg. ANRespToCHNSP), performs the two-step response effect analysis controlling for the effect of any intrinsic vocalisation pattern of the 
#target speaker, and outputs the results of stastitical analyses as a tibble. Note that here, we are only doing the analyses on IVIs.
#Here, we implement two steps: get the previous step size beta values, and then, response effect beta values based on residuals of the Current IVI ~ Previous IVI analyses.
#Note that this is done in two steps because the CurrStepSi ~ PrevStSi analyses are carried out on all non-NaN steps, but the response analyses are only done on steps
#associated with non-NA responses
#The third input is CILvl, which is the desired confidence level to compute confidence interval in the form of <percent/100>. That is, for 95% confidence intervals, 
#CILvl = 0.95 (correponding to a p-value alpha threshold = 0.05) and so on and so forth. NOTE THAT in the master function WriteOpToFile_RespEffBetas, CILvl is 
#specified as a percent value (i.e., 95 instead 0.95, in the example given here), and that value gets converted to <percent/100> before passing on to these functions.
#Note also that this function implements the protocol for validation data: human-listener labelled 5-minute sections and the corresaponding LENA labelled sections,
#by using age and age:id interaction as random effects (since age isn't an axis along which there is much variation--and we aren't interested in that for
#the validation data)
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GetRespEff_IVI_w_PrevStSiCtrl_ValData <- function(FilesToLoad,RespToSpkr,CILvl){
  
  InfAge_Months <- c(); RespWin_Seconds <- c() #initialise vectors to iteratively store output in (we don't need InfAge_Months, but we are going to concatenate 
  #the validation and LENA tables, so we have this for consistency)
  PrevSt_Beta <- c(); PrevStP <- c(); PrevStCI_Lwr <- c(); PrevStCI_Upper <- c()
  Response_Beta <- c(); ResponseP <- c(); ResponseCI_Lwr <- c(); ResponseCI_Upper <- c()
  Ctr <- 0; #initialise counter variable
  
  for (i in FilesToLoad){ #go through file list
    if (str_contains(i,RespToSpkr)){ #check if file name has the target string
      
      DataTab <- read_csv(i); attach(DataTab) #read table
      RespWindowVals <- gsub('Response_','',colnames(DataTab)[1:11]) #get response window values: the first 11 cols of the data table is responses, 
      #for response windows 0.5, and 1 through 10 seconda, at 1 s increments. Picking these out and removing the 'Response_' string gives us just the numbers
      
      #NOTE that we are NOT subsetting for age
      ID <- as_factor(DataTab$InfantID); AgeVar <- scale(DataTab$AgeMonths) #get ID and age
      CurrVar <- log10(DataTab$CurrIVI + (10^-10)); PrevVar <- log10(DataTab$PrevIVI + (10^-10)) #log current and previous IVIs
      
      for (j in 1:numel(RespWindowVals)){ #Go through the different response windows
        
        #print(j)
        Ctr <- Ctr + 1 #update Ctr
        
        #run just prev var model and get residuals
        LmerMdl_PrevSt <- lmer(scale(CurrVar) ~ (1|ID) + (1|AgeVar) + (1|AgeVar:ID) + scale(PrevVar),na.action=na.exclude)
        PrevStSummary <- summary(LmerMdl_PrevSt); PrevStCIs <- confint(LmerMdl_PrevSt,level = CILvl)
        ResidVar <- resid(LmerMdl_PrevSt)
        
        TabForLm <- tibble(ResidVar,DataTab[,j]) #get table for linear model so we can subset only non-NaN responses; Note that for the response vector, we just index the get j-th response vector from DataTab
        #for j-th response window value. Indexing this way makes it so that the column name from DataTab is preserved
        colnames(TabForLm)[2] <- 'CurrRespVar' #rename the second column to a standard name as opposed to the preserved column name from Data
        LmSubsetTab <- filter(TabForLm,!is.nan(CurrRespVar)) #filter for non-NaN repsonse values ONLY
        ResponseForLm <- as_factor(LmSubsetTab$CurrRespVar) 
        
        #run response effect on residuals
        LmMdl_Resp <- lm(scale(LmSubsetTab$ResidVar) ~ ResponseForLm) #+ poly(Age,2,raw = TRUE) + poly(Age,2,raw = TRUE)*ResponseForLm)
        RespSummary <- summary(LmMdl_Resp); RespCIs <- confint(LmMdl_Resp,level = CILvl)
        
        #store results
        RespWin_Seconds[Ctr] <- as.numeric(RespWindowVals[j]); InfAge_Months[Ctr] <- NA
        PrevSt_Beta[Ctr] <- PrevStSummary$coefficients[2,1] 
        PrevStP[Ctr] <- PrevStSummary$coefficients[2,5] 
        PrevStCI_Lwr[Ctr] <- PrevStCIs[6,1]
        PrevStCI_Upper[Ctr] <- PrevStCIs[6,2]
        
        Response_Beta[Ctr] <- RespSummary$coefficients[2,1] 
        ResponseP[Ctr] <- RespSummary$coefficients[2,4]
        ResponseCI_Lwr[Ctr] <- RespCIs[2,1]
        ResponseCI_Upper[Ctr] <- RespCIs[2,2]
      } 
      detach(DataTab)
    }
  }
  
  OpTab <- tibble(RespWin_Seconds,InfAge_Months,
                  PrevSt_Beta,PrevStP,PrevStCI_Lwr,PrevStCI_Upper,
                  Response_Beta,ResponseP,ResponseCI_Lwr,ResponseCI_Upper)
  return(OpTab)
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Fn 6: #This function takes the list of files in the directory (FilesToLoad) as well as a string identifying the target speaker and responder (RespToSpkr;
#eg. ANRespToCHNSP), performs the response effect analysis *WITHOUT* controlling for the effect of any intrinsic vocalisation pattern of the 
#target speaker, and outputs the results of stastitical analyses as a tibble
#The third input is CILvl, which is the desired confidence level to compute confidence interval in the form of <percent/100>. That is, for 95% confidence intervals, 
#CILvl = 0.95 (correponding to a p-value alpha threshold = 0.05) and so on and so forth. NOTE THAT in the master function WriteOpToFile_RespEffBetas, CILvl is 
#specified as a percent value (i.e., 95 instead 0.95, in the example given here), and that value gets converted to <percent/100> before passing on to these functions.
#Note that this function implements the protocol for LENA day-long data, and only for IVI.
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GetRespEff_IVI_NoPrevStSiCtrl_LENA <- function(FilesToLoad,RespToSpkr,CILvl){
  
  InfAge_Months <- c(); RespWin_Seconds <- c() #initialise vectors to iteratively store output in
  Response_Beta <- c(); ResponseP <- c(); ResponseCI_Lwr <- c(); ResponseCI_Upper <- c()
  Ctr <- 0; #initialise counter variable
  
  for (i in FilesToLoad){ #go through file list
    if (str_contains(i,RespToSpkr)){ #check if file name has the target string
      
      DataTab <- read_csv(i); attach(DataTab)  #read table
      RespWindowVals <- gsub('Response_','',colnames(DataTab)[1:11]) #get response window values: the first 11 cols of the data table is responses, 
      #for response windows 0.5, and 1 through 10 seconda, at 1 s increments. Picking these out and removing the 'Response_' string gives us just the numbers
      
      for (k in c(3, 6, 9, 18)){ #do analyses separately for different ages
        
        SubsetTab <- filter(DataTab, AgeMonths == k) #subset for age in months
        
        for (j in 1:numel(RespWindowVals)){ #Go through the different response windows
          
          Ctr <- Ctr + 1
          SubsetForCurrRespWin <- tibble(SubsetTab$CurrIVI,SubsetTab$InfantID,SubsetTab[,j]) #Get the subsetted table with only the relevant vars: infant id, current
          #IVI, and the response vector for the relavent response window. Note that for the response vector, we just index the j-th response vector from SubsetTab
          #for j-th response window value. Also notethat the column names from SubsetTab are preserved
          colnames(SubsetForCurrRespWin) <- c('CurrIVI_kj','InfantID_kj','CurrRespVar') #rename columns (because, as of now, these columns are going to be names SubsetTab$CurrIVI, etc.)
          
          TabForLmer <- filter(SubsetForCurrRespWin,!is.nan(CurrRespVar)) #filter NaN responses
          IDforLmer <- as_factor(TabForLmer$InfantID_kj); RespforLmer <- as_factor(TabForLmer$CurrRespVar)
          CurrVar <- log10(TabForLmer$CurrIVI_kj + (10^-10)) #log variables
          
          LmerMdl_Resp <- lmer(scale(CurrVar) ~  RespforLmer + (1|IDforLmer))  #run response effect with random effect for ID
          RespSummary <- summary(LmerMdl_Resp); RespCIs <- confint(LmerMdl_Resp,level = CILvl)
          
          RespWin_Seconds[Ctr] <- as.numeric(RespWindowVals[j]); InfAge_Months[Ctr] <- k
          Response_Beta[Ctr] <- RespSummary$coefficients[2,1] 
          ResponseP[Ctr] <- RespSummary$coefficients[2,5]
          ResponseCI_Lwr[Ctr] <- RespCIs[4,1]
          ResponseCI_Upper[Ctr] <- RespCIs[4,2]
        } 
      }
      detach(DataTab)
    }
  }
  
  OpTab <- tibble(RespWin_Seconds, InfAge_Months,
                  Response_Beta,ResponseP,ResponseCI_Lwr,ResponseCI_Upper)
  return(OpTab)
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Fn 7: #This function takes the list of files in the directory (FilesToLoad) as well as a string identifying the target speaker and responder (RespToSpkr;
#eg. ANRespToCHNSP), performs the response effect analysis *WITHOUT* controlling for the effect of any intrinsic vocalisation pattern of the 
#target speaker, and outputs the results of stastitical analyses as a tibble
#The third input is CILvl, which is the desired confidence level to compute confidence interval in the form of <percent/100>. That is, for 95% confidence intervals, 
#CILvl = 0.95 (correponding to a p-value alpha threshold = 0.05) and so on and so forth. NOTE THAT in the master function WriteOpToFile_RespEffBetas, CILvl is 
#specified as a percent value (i.e., 95 instead 0.95, in the example given here), and that value gets converted to <percent/100> before passing on to these functions.
#Note that this function implements the protocol for validation data: human-listener labelled 5-minute sections and the corresaponding LENA labelled sections,
#by using age and age:id interaction as random effects (since age isn't an axis along which there is much variation--and we aren't interested in that for
#the validation data). Note also that this function only does the analyses on IVIs. 
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GetRespEff_IVI_NoPrevStSiCtrl_ValData <- function(FilesToLoad,RespToSpkr,CILvl){
  
  InfAge_Months <- c(); RespWin_Seconds <- c() #initialise vectors to iteratively store output in
  Response_Beta <- c(); ResponseP <- c(); ResponseCI_Lwr <- c(); ResponseCI_Upper <- c()
  Ctr <- 0; #initialise counter variable
  
  for (i in FilesToLoad){ #go through file list
    if (str_contains(i,RespToSpkr)){ #check if file name has the target string
      
      DataTab <- read_csv(i); attach(DataTab) #read table
      RespWindowVals <- gsub('Response_','',colnames(DataTab)[1:11]) #get response window values: the first 11 cols of the data table is responses, 
      #for response windows 0.5, and 1 through 10 seconda, at 1 s increments. Picking these out and removing the 'Response_' string gives us just the numbers
      
      for (j in 1:numel(RespWindowVals)){ #Go through the different response windows
      
        Ctr <- Ctr + 1
        SubsetTab <- tibble(DataTab$CurrIVI,DataTab$InfantID,DataTab$AgeMonths,DataTab[,j]) #Get the subsetted table with only the relevant vars: infant id, current
        #IVI, and the response vector for the relavent response window. Note that for the response vector, we just index the j-th response vector from SubsetTab
        #for j-th response window value. Also note that the column names from DataTab are preserved
        colnames(SubsetTab) <- c('CurrIVI_j','InfantID_j','AgeMonths_j','CurrRespVar') #rename columns (cuz as of now, these columns would be names as DataTab$CurrIVI, etc)
        
        TabForLmer <- filter(SubsetTab,!is.nan(CurrRespVar)) #filter NaN responses
        ID <- as_factor(TabForLmer$InfantID_j); ResponseVar <- as_factor(TabForLmer$CurrRespVar) #get ID, and response
        CurrVar <- log10(TabForLmer$CurrIVI_j + (10^-10)); AgeVar <- scale(TabForLmer$AgeMonths_j)
        
        LmerMdl_Resp <- lmer(scale(CurrVar) ~ ResponseVar + (1|ID) + (1|AgeVar) + (1|ID:AgeVar))  #run response effect on residuals
        RespSummary <- summary(LmerMdl_Resp); RespCIs <- confint(LmerMdl_Resp,level = CILvl)
        
        RespWin_Seconds[Ctr] <- as.numeric(RespWindowVals[j]); InfAge_Months[Ctr] <- NA
        Response_Beta[Ctr] <- RespSummary$coefficients[2,1] 
        ResponseP[Ctr] <- RespSummary$coefficients[2,5]
        ResponseCI_Lwr[Ctr] <- RespCIs[6,1]
        ResponseCI_Upper[Ctr] <- RespCIs[6,2]
      } 
      detach(DataTab)
    }
  }
  
  OpTab <- tibble(RespWin_Seconds, InfAge_Months,
                  Response_Beta,ResponseP,ResponseCI_Lwr,ResponseCI_Upper)
  return(OpTab)
}
