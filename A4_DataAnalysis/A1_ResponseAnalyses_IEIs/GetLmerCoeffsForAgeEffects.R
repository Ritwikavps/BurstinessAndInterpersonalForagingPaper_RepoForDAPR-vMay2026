#This set of functions computes the response betas with and without the previous IEI control, as well as previous IEI betas where applicable at the 
#recording level, for LENA day-long data as well as the validation data (LENA 5 min, human-listener labelled data with all adult vocs included, as
#well as human-listener labelled data with only child-directed adult vocs included), for infant and adult vocs, for 3, 6, 9, and 18 months ONLY.
#Then, these recording level betas are used to compute age effects for these betas.

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Fn 1: This function takes the table with the recording level betas and runs the age effects lmer and writes the output to file.

#Inputs:
#- RecLvlBetasTab: table with the recording level betas
#- CILvl: the Conf. interval we want
#- DestinationPath: the path where output file shoudl be written
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GetLmerAgeEffOnRespBetaAndWriteOpToFile <- function(RecLvlBetasTab,CILvl,DestinationPath){
  
  attach(RecLvlBetasTab)
  
  CIStr <- gsub('\\.','_',strcat(as.character(CILvl),'prc')) #convert the CILvl to a string, add 'prc' to signify percent, then sub the decimal point ('.')--if it
  #is present in the CILvl provided--with underscore ('_') (for easier variable naming that translates well across R and MATLAB). Now, we can use this string to 
  #add to final file name, so we know what teh CI lvl is for the results table
  CILvl <- CILvl/100 #convert to <percent/100> such that a conf lvl of 99.9 is expressed as 0.999, which is the required R syntax
  
  #initialise vectors to iteratively store output in
  RespWindow_Temp <- c(); BetaType <- c(); DataType_Temp <- c(); Spkr_Temp <- c(); #Non-stats identifiers; eg. response window etc
  Age1Eff <- c(); Age1P <- c(); Age1CI_Lwr <- c(); Age1CI_Upper <- c() #age (linear) results
  Age2Eff <- c(); Age2P <- c(); Age2CI_Lwr <- c(); Age2CI_Upper <- c() #age^2 results
  InterceptVal <- c(); InterceptCI_Lwr <- c(); InterceptCI_Upper <- c()
  
  Ctr <- 0 #intialise counter variable
  
  #get unique values of responsewindow and step varible
  u_RespWin <- unique(RecLvlBetasTab$RespWin_Seconds); u_DataType <- unique(RecLvlBetasTab$DataType); u_Spkr <- unique(RecLvlBetasTab$ResponseType) 
  
  for (i_rwin in u_RespWin){ #do analyses for each data type, response window, and speaker/responder combo
    for (i_spkr in u_Spkr){
      for (i_dtype in u_DataType){
      
        SubsetTab <- filter(RecLvlBetasTab, RespWin_Seconds == i_rwin & ResponseType == i_spkr & DataType == i_dtype) #subset relevant table
        SubsetTab$InfID <- as_factor(SubsetTab$InfID) #make infant ID categorical variable
        #Note that we are not scaling anything, cuz we want to see how the effect looks for age, not scaled age
        
        for (i_beta in 4:6){ #go through the three effect sizes we are interested in (PrevSt_Beta, Response_Beta_wCtrl,Response_Beta_woCtrl)
          #Note that this indexing is based on how the input table is structured

          Ctr <- Ctr + 1 #increment counter variable

          #(This whole bit below is to avoid a weird error in the lmer model; 
          #see error: '"Error in KhatriRao(sm, t(mm)) : (p <- ncol(X)) == ncol(Y) is not TRUE" on stack exchange)
          TabForLm <- tibble(SubsetTab[,i_beta],SubsetTab$InfID,SubsetTab$InfAge_Months) #make tibble with relevnt vars
          colnames(TabForLm) <- c('BetaVar','IDVar','AgeVar') #rename vars
          BetaVarForTest <- TabForLm$BetaVar; IDVarForTest <- TabForLm$IDVar; AgeVarForTest <- TabForLm$AgeVar; #assign vars
          
          print(i_rwin)
          print(i_spkr)
          print(i_dtype)
          LmerMdl <- lmer(BetaVarForTest ~  (1|IDVarForTest) + poly(AgeVarForTest,2, raw = TRUE), na.action=na.exclude) #Do lmer test
          LmerSummary <- summary(LmerMdl); 
          LmerCIs <- confint(LmerMdl,level = CILvl) #get stats results
        
          #store results
          RespWindow_Temp[Ctr] <- i_rwin; BetaType[Ctr] <- colnames(RecLvlBetasTab)[i_beta] 
          DataType_Temp[Ctr] <- i_dtype; Spkr_Temp[Ctr] <- i_spkr
          
          InterceptVal[Ctr] <- LmerSummary$coefficients[1,1]
          InterceptCI_Lwr[Ctr] <- LmerCIs[3,1]
          InterceptCI_Upper[Ctr] <- LmerCIs[3,2]
          
          Age1Eff[Ctr] <- LmerSummary$coefficients[2,1]
          Age1P[Ctr] <- LmerSummary$coefficients[2,5]
          Age1CI_Lwr[Ctr] <- LmerCIs[4,1]
          Age1CI_Upper[Ctr] <- LmerCIs[4,2]
          
          Age2Eff[Ctr] <- LmerSummary$coefficients[3,1]
          Age2P[Ctr] <- LmerSummary$coefficients[3,5]
          Age2CI_Lwr[Ctr] <- LmerCIs[5,1]
          Age2CI_Upper[Ctr] <- LmerCIs[5,2]
        }
      }
    }
  }
  
  detach(RecLvlBetasTab)
  
  RespWindow_s <- RespWindow_Temp; DataType <- DataType_Temp; SpkrAndResp <- Spkr_Temp; #rename vars
  OpTab <- tibble(DataType,SpkrAndResp,RespWindow_s,BetaType,
                  InterceptVal,InterceptCI_Lwr,InterceptCI_Upper,
                  Age1Eff,Age1P,Age1CI_Lwr,Age1CI_Upper,
                  Age2Eff,Age2P,Age2CI_Lwr,Age2CI_Upper)
  
  OpFname <- strcat(DestinationPath,strcat(strcat('AgeEffects_IviOnly_CI',CIStr),'.csv')) #get file name
  write.csv(OpTab, file = OpFname,row.names=FALSE) #write file
  return(OpTab)
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
#Fn 2: #This function takes the list of files to run the analyses on, runs GetRecLvlBetas() for all data types and speaker/response combos, and compiles 
#all results (at the recording day level) into one output table, and writes the output table to file. 

#Inputs to this function are:
#- the list of working directory paths (WorkingDir)
#- the string pattern to match to get the required files (FilePattern)
#- the list of data types we are dealing with (eg. LENA, LENA5min, Hum) (DataType)
#- file path where the output files are written to (DestinationPath)
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GetRecLvlBetasFinalTabAndWriteToFile <- function(WorkingDir,FilePattern,DataType,DestinationPath){
  
  FinalOpTab <- NULL #Initialise final output tibble
  
  for (i in 1:numel(WorkingDir)){ #go through list of working directories (indexed in the same order as DataType): for all four data types: LENA day-long, 
    #human-listener labelled 5 min (with all adult vocs), human-listener labelled 5 min (only child-dir adult vocs), and LENA 5 min
    
    setwd(WorkingDir[i]) #set working directory
    FilesToLoad <- list.files(path = getwd(),pattern = FilePattern)  #get list of required files
    
    for (RespType in c('ANRespToCHNSP','CHNSPRespToAN')){ #go through the response-to-speaker types
      StatsOp_Temp <- GetRecLvlBetas(FilesToLoad,RespType,DataType[i]) #get output table
      
      StatsOp_Temp$ResponseType <- rep(RespType,nrow(StatsOp_Temp)) #add response type column
      StatsOp_Temp$DataType <- rep(DataType[i],nrow(StatsOp_Temp)) #add DataType column
      FinalOpTab <- bind_rows(FinalOpTab,StatsOp_Temp) #append to final output table
    }
  }
  
  OpFileName <- strcat(DestinationPath,'RecLvlPrevStSizeAndRespBetas.csv') #concatenate strings for output file name
  write.csv(FinalOpTab, file = OpFileName,row.names=FALSE) #write file
  return(FinalOpTab)
}


#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Fn 3: This function takes in files with IVIs and computes the recording level prev IVI beta, and response betas with and without the prev IVI control.
# FilesToLoad is the list of .csv files with IVIs to read in, RespType is the string that specifies the speaker and the responder; and DataType is the
#string that specifies the type of data that is being read in (LENA day-long, LENA 5 min, human listener-labelled with only child-directed adult vocs, 
#human listener-labelled with all adult vocs)
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GetRecLvlBetas <- function(FilesToLoad,RespType,DataType){
  
  InfAge_Months <- c(); RespWin_Seconds <- c(); InfID <- c(); #initialise vectors to iteratively store output in; #StepVar <- c(); 
  PrevSt_Beta <- c(); Response_Beta_wCtrl <- c(); Response_Beta_woCtrl <- c(); 
  Ctr <- 0; #initialise counter variable
  
  for (i in FilesToLoad){ #go through file list
    if (str_contains(i,RespType)){ #check if file name has the target string indicating speaker and responder types
      
      DataTab <- read_csv(i); attach(DataTab) #read table and attach
      RespWindowVals <- gsub('Response_','',colnames(DataTab)[1:11]) #get response window values: the first 11 cols of the data table is responses, 
      #for response windows 0.5, and 1 through 10 seconda, at 1 s increments. Picking these out and removing the 'Response_' string gives us just the numbers
      u_ID <- unique(DataTab$InfantID) #get list of unique IDs
      
      for (k_Age in c(3, 6, 9, 18)){ #do analyses separately for different ages
        for (k_ID in u_ID){ #do analyses separately for each ID (so, if we separate data by ID and age, we get to analyse things at the recording level)
        
          SubsetTab <- filter(DataTab, AgeMonths == k_Age & InfantID == k_ID) #subset for age in months and indant ID
          
          if (nrow(SubsetTab) > 1 & numel(na.omit(SubsetTab$CurrIVI)) > 1 & numel(na.omit(SubsetTab$PrevIVI)) > 1){ #check to make sure that the 
            #subsetted table is not empty AND that there are enough non-NA IVI values to run the analyses

            CurrVar <- log10(SubsetTab$CurrIVI + (10^-10)); PrevVar <- log10(SubsetTab$PrevIVI + (10^-10)) #log current and previous IVIs
            
            for (j in 1:numel(RespWindowVals)){ #Go through the different response windows
              
              Ctr <- Ctr + 1 #increment counter
              ResponseForAge_k <- SubsetTab[,j] #get j-th response vector for j-th response window value; Note that indexing this way makes it so that responseForAge_k is a tibble 
              #with one column, and the column name from SubsetTab is preserved
              
              #run just prev IVI model and get residuals
              LmMdl_PrevSt <- lm(scale(CurrVar) ~ scale(PrevVar),na.action=na.exclude) #exclude NA values of the input variables, if any, in the fit
              PrevStSummary <- summary(LmMdl_PrevSt); 
              ResidVar <- resid(LmMdl_PrevSt)
            
              TabForLm <- tibble(ResidVar,ResponseForAge_k,CurrVar) #get table for linear model so we can subset only non-NaN responses
              colnames(TabForLm)[2] <- 'CurrRespVar' #rename the second column to a standard name as opposed to the preserved column name from SubsetTab
              LmSubsetTab <- filter(TabForLm,!is.nan(CurrRespVar)) #filter for non-NaN repsonse values ONLY
              ResponseForLm <- as_factor(LmSubsetTab$CurrRespVar) #make response categorical variable
              
              if (nlevels(ResponseForLm) > 1){ #check that there are both yes and no response
              
                LmMdl_Resp_wCtrl <- lm(scale(LmSubsetTab$ResidVar) ~ ResponseForLm) #run response effect on residuals: with control test
                wCtrl_RespSummary <- summary(LmMdl_Resp_wCtrl); 
                
                LmMdl_Resp_woCtrl <- lm(scale(LmSubsetTab$CurrVar) ~ ResponseForLm) #run without control test
                woCtrl_RespSummary <- summary(LmMdl_Resp_woCtrl);
                
                #store results
                Response_Beta_wCtrl[Ctr] <- wCtrl_RespSummary$coefficients[2,1] 
                Response_Beta_woCtrl[Ctr] <- woCtrl_RespSummary$coefficients[2,1]
                
              } else { #if there aren't BOTH yes and no responses, we can't do response analyses, so assign NA to those beta values
                
                Response_Beta_wCtrl[Ctr] <- NA 
                Response_Beta_woCtrl[Ctr] <- NA
              }
              
              #store results
              RespWin_Seconds[Ctr] <- as.numeric(RespWindowVals[j]); InfAge_Months[Ctr] <- k_Age; InfID[Ctr] <- k_ID
              PrevSt_Beta[Ctr] <- PrevStSummary$coefficients[2,1] 
            }
          } 
        }
      }
      detach(DataTab)
    }
  }
  
  OpTab <- tibble(RespWin_Seconds,InfAge_Months,InfID,
                  PrevSt_Beta,Response_Beta_wCtrl,Response_Beta_woCtrl)
  return(OpTab)
}