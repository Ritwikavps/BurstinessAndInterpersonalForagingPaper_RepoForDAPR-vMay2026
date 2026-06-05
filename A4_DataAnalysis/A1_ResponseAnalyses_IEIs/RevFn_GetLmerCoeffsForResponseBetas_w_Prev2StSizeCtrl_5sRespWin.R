#Fn 1: #This function takes the list of files to run the analyses on, runs the following two functions, and writes output. Note that this the master function that
#runs the illustrative response effect analyses with the previous 2 IVI control, and all inputs for subsequent functions are specified here

#Inputs to this function are - the list of working directory paths (WorkingDir)
#- the string pattern to match to get the required files (FilePattern)
#- the list of data types we are dealing with (eg. LENA, LENA5min, Hum) (DataType)
#- the path to which output should be written (WriteOpPath)
#- the string identifying whether we are running the stats with or without previous step size control (should be 'w2ctrl')
#- the desired confidence level to compute confidence interval in the form of a percent value. That is, for 95% confidence intervals, CILvl = 95 (correponding to 
# a p-value alpha threshold = 0.05) and so on and so forth (CILvl)
# a string input summarising the condition that allows to toggle between whether the prev-to-prev IVI term is (Prev2IVI) OR (PrevIVI + Prev2IVI)

#Stats results for with (or without, as applicable; specified by the PrevStSiCtrlOrNo input) previous IVI control is done for all four data types: LENA day-long, 
#human-listener labelled 5 min (with all adult vocs), human-listener labelled 5 min (only child-dir adult vocs), and LENA 5 min, and written into a single output file.
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
WriteOpToFile_RespEffBetas_2PrevStSizeCtrl <- function(WorkingDir,FilePattern,DataType,WriteOpPath,PrevStSiCtrlorNo,CILvl,Prev2Var_Cond){
  
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
      if (strcmp(PrevStSiCtrlorNo,'w2Ctrl')){ #run appropriate function depending on whether prev st size control is being implemented or not
        StatsOp_Temp <- GetRespEff_w_Prev2StSiCtrl_IVI(FilesToLoad,RespType,DataType[i],CILvl,Prev2Var_Cond)
      } else {
        stop('This is only for the previous 2 IVI control. Check inputs!')
      }
      StatsOp_Temp$ResponseType <- rep(RespType,nrow(StatsOp_Temp)) #add response type column
      StatsOp_Temp$DataType <- rep(DataType[i],nrow(StatsOp_Temp)) #add DataType column
      FinalOpTab <- bind_rows(FinalOpTab,StatsOp_Temp) #append to final output table
    }
  }
  
  if (strcmp(PrevStSiCtrlorNo,'w2Ctrl')){ #get output filename appropraitely
    #get file names to save
    Fname <- paste('Rev_RespEff_W_Prev2StSizCtrl_',Prev2Var_Cond,'_5sRespWin_VarsScaleLog_CorpusLvl_IviOnly_CI',CIStr,'.csv',sep='') 
  } else {
    stop('This is only for the previous 2 IVI control. Check inputs!')
  }
  
  setwd(WriteOpPath)
  write.csv(FinalOpTab, file = Fname,row.names=FALSE) #write file
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Fns 2: This function takes the list of files to run analyses on, and assigns the appropriate function (for LENA daylong or validation data) to get the output tibble, 
#WITH the previous 2 step sizes control protocol.
#Inputs: - FilesToLoad: the list of files in the directory 
# - RespType: A string of the form <Responder>RespTo<Spkr> that identifies the speaker type and the responder type
# - DataType: a string identifying the labelling method, i.e.,LENA, LENA5min, or Hum
# - CILvl: the desired confidence level to compute confidence interval in the form of <percent/100>. That is, for 95% confidence intervals, CILvl = 0.95 
#(correponding to a p-value alpha threshold = 0.05) and so on and so forth. NOTE THAT in the master function WriteOpToFile_RespEffBetas, CILvl is specified
#as a percent value (i.e., 95 instead 0.95, in the example given here), and that value gets converted to <percent/100> before passing on to these functions
# - Prev2Var_Cond: this condition allows to toggle between whether the prev-to-prev IVI term is (Prev2IVI) OR (PrevIVI + Prev2IVI)
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GetRespEff_w_Prev2StSiCtrl_IVI <- function(FilesToLoad,RespType,DataType,CILvl,Prev2Var_Cond){
  if (strcmp('LENA',DataType)){ #check DataType string
    OpTab <- GetRespEff_IVI_w_Prev2StSiCtrl_LENA(FilesToLoad,RespType,CILvl,Prev2Var_Cond) #assign relevant function
  }else if (strcmp('LENA5min',DataType) || strcmp('Hum-AllAd',DataType) || strcmp('HumChildDirAdOnly',DataType)){
    OpTab <- GetRespEff_IVI_w_Prev2StSiCtrl_ValData(FilesToLoad,RespType,CILvl,Prev2Var_Cond)
  } else {
    stop('Data type not one of the following: LENA, LENA5min, Hum-AllAd, HumChildDirAdOnly')
  }
  return(OpTab)
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Fn 3: #This function takes the list of files in the directory (FilesToLoad), a string identifying the target speaker and responder (RespToSpkr;
#eg. ANRespToCHNSP), a string identifying the condition associated with the prev-to-prev IVI control (whether the prev-to-prev IVI control terms should
#be (Prev2IVI) or. (Prev2IVI + prevIVI) (Prev2Var_Cond; as, respectively, 'not_sum' and 'sum'), and the confidence interval level to compute confidence 
#intervals, and performs the two-step response effect analysis controlling for the effect of any intrinsic vocalisation pattern of the target 
#speaker (by regressing current IVI against prev IVI and the effect of the prev-to-prev IVIs; see below), and outputs the results of stastitical 
#analyses as a tibble. Note that here, we are only doing the analyses on IVIs.
#Here, we implement two steps: get the previous IVI + previous 2 IVIs beta values, and then, response effect beta values based on residuals of the 
#Current IVI ~ Previous IVI + (Prev2IVI control term) analyses. Note that this is done in two steps because the 
#CurrStepSi ~ PrevStSi + (Prev2IVI control term) analyses are carried out on all non-NaN steps, but the response analyses are only done 
#on steps associated with non-NA responses
#The third input is CILvl, which is the desired confidence level to compute confidence interval in the form of <percent/100>. That is, for 95% confidence intervals, 
#CILvl = 0.95 (correponding to a p-value alpha threshold = 0.05) and so on and so forth. NOTE THAT in the master function WriteOpToFile_RespEffBetas, CILvl is 
#specified as a percent value (i.e., 95 instead 0.95, in the example given here), and that value gets converted to <percent/100> before passing on to these functions.
#Note that this function implements the protocol for LENA day-long data.
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GetRespEff_IVI_w_Prev2StSiCtrl_LENA <- function(FilesToLoad,RespToSpkr,CILvl,Prev2Var_Cond){
  
  InfAge_Months <- c(); RespWin_Seconds <- c() #initialise vectors to iteratively store output in; #StepVar <- c(); 
  PrevSt_Beta <- c(); PrevStP <- c(); PrevStCI_Lwr <- c(); PrevStCI_Upper <- c()
  Prev2St_Beta <- c(); Prev2StP <- c(); Prev2StCI_Lwr <- c(); Prev2StCI_Upper <- c()
  Response_Beta <- c(); ResponseP <- c(); ResponseCI_Lwr <- c(); ResponseCI_Upper <- c()
  NumObs_PrevStMdl <- c(); NumObs_RespMdl <- c(); #Number of observations
  MargR2_PrevStMdl <- c(); CondR2_PrevStMdl <- c(); #note that teh marginal Rsq is the proportion of variance explained by the
  #fixed effects only while the conditional Rsq is the proportion of variance explained by the fixed and random effects combined
  Rsq_RespMdl <- c(); #Because the response model is always a simple IEI residual ~ response variable linear model, we don't report
  #adjusted rsq
  Ctr <- 0; #initialise counter variable
  
  for (i in FilesToLoad){ #go through file list
    if (str_contains(i,RespToSpkr)){ #check if file name has the target string indicating speaker and responder types
      
      DataTab <- read_csv(i); attach(DataTab) #read table and attach
      RespWindowVals <- gsub('Response_','',colnames(DataTab)[1]) #get response window values: the first of the data table is the 5 s response window
      #response variable, for response windows 0.5, and 1 through 10 seconda, at 1 s increments. Picking these out and removing the 'Response_' 
      #string gives us just the numbers
      
      for (k in c(3, 6, 9, 18)){ #do analyses separately for different ages
        
        SubsetTab <- filter(DataTab, AgeMonths == k) #subset for age in months
        IDforAge_k <- as_factor(SubsetTab$InfantID); #get ID
        CurrVar <- log10(SubsetTab$CurrIVI + (10^-10)); PrevVar <- log10(SubsetTab$PrevIVI + (10^-10)); #log current and prev IVIs
        #log (prev + prev-to-prev) IVI: we can either use (Prev2IVI) or (PrevIVI + Prev2IVI) as the explanatory variable. The if statement below 
        #accounts for these options
        if (strcmp(Prev2Var_Cond,'sum')){
          Prev2Var <- log10(SubsetTab$PrevIVI + SubsetTab$Prev2IVI + (10^-10)) 
        } else if (strcmp(Prev2Var_Cond,'not_sum')){
          Prev2Var <- log10(SubsetTab$Prev2IVI + (10^-10))
        } else {
          stop('Prev-to-prev IVI condition should be either sum or no_sum')
        }
        
        for (j in 1:numel(RespWindowVals)){ #Go through the different response windows
          #get response window values: the first of the data table is the 5 s response window
          #(but keeping the structure that allows for looping through multiple response window values so the functionality exists)
          
          fprintf('\n')
          fprintf('-------------------------------------------------------------------------------------------------------------\n')
          fprintf('File being analysed: %s; response type: %s; infant age = %i; response window value = %s seconds \n',
                  i, RespToSpkr, k, RespWindowVals[j])
          
          Ctr <- Ctr + 1 #increment counter
          ResponseForAge_k <- SubsetTab[,j] #get j-th response vector for j-th response window value; Note that indexing this way makes it so that responseForAge_k is a tibble 
          #with one column, and the column name from SubsetTab is preserved
          
          #run just prev IVI model and get residuals
          LmerMdl_PrevSt <- lmer(scale(CurrVar) ~ (1|IDforAge_k) + scale(PrevVar) + scale(Prev2Var),na.action=na.exclude) #exclude NA values of the input variables, if any, in the fit
          PrevStSummary <- summary(LmerMdl_PrevSt); PrevStCIs <- confint(LmerMdl_PrevSt,level = CILvl)
          PrevStMdlRsq <- r2(LmerMdl_PrevSt) #estimates marginal and conditional Rsq
          ResidVar <- resid(LmerMdl_PrevSt) #get residuals
          
          fprintf('Previous IEI control model results: \n')
          print(PrevStSummary)
          fprintf('\n')
          fprintf('Previous IEI control confidence intervals: \n')
          print(PrevStCIs)
          
          TabForLm <- tibble(ResidVar,ResponseForAge_k) #get table for linear model so we can subset only non-NaN responses
          colnames(TabForLm)[2] <- 'CurrRespVar' #rename the second column to a standard name as opposed to the preserved column name from SubsetTab
          LmSubsetTab <- filter(TabForLm,!is.nan(CurrRespVar)) #filter for non-NaN repsonse values ONLY
          ResponseForLm <- as_factor(LmSubsetTab$CurrRespVar) 
          
          #run response effect on residuals
          LmMdl_Resp <- lm(scale(LmSubsetTab$ResidVar) ~ ResponseForLm) #+ poly(Age,2,raw = TRUE) + poly(Age,2,raw = TRUE)*ResponseForLm)
          RespSummary <- summary(LmMdl_Resp); RespCIs <- confint(LmMdl_Resp,level = CILvl)
          
          fprintf('\n')
          fprintf('Response effect model results: \n')
          print(RespSummary)
          fprintf('\n')
          fprintf('Response effect confidence intervals: \n')
          print(RespCIs)
          
          #store results
          RespWin_Seconds[Ctr] <- as.numeric(RespWindowVals[j]); InfAge_Months[Ctr] <- k #StepVar[Ctr] <- gsub('Curr','',colnames(SubsetTab)[j]); 
          NumObs_PrevStMdl[Ctr] <- nobs(LmerMdl_PrevSt); NumObs_RespMdl[Ctr] <- nobs(LmMdl_Resp)
          MargR2_PrevStMdl[Ctr] <- PrevStMdlRsq$R2_marginal; CondR2_PrevStMdl[Ctr] <- PrevStMdlRsq$R2_conditional
          Rsq_RespMdl[Ctr] <- RespSummary$r.squared
            
          PrevSt_Beta[Ctr] <- PrevStSummary$coefficients[2,1] 
          PrevStP[Ctr] <- PrevStSummary$coefficients[2,5] 
          PrevStCI_Lwr[Ctr] <- PrevStCIs[4,1]
          PrevStCI_Upper[Ctr] <- PrevStCIs[4,2]
          
          Prev2St_Beta[Ctr] <- PrevStSummary$coefficients[3,1]
          Prev2StP[Ctr] <- PrevStSummary$coefficients[3,5]
          Prev2StCI_Lwr[Ctr] <- PrevStCIs[5,1]
          Prev2StCI_Upper[Ctr] <- PrevStCIs[5,2]
          
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
                  Prev2St_Beta,Prev2StP,Prev2StCI_Lwr,Prev2StCI_Upper,
                  Response_Beta,ResponseP,ResponseCI_Lwr,ResponseCI_Upper,
                  NumObs_PrevStMdl, NumObs_RespMdl,
                  MargR2_PrevStMdl, CondR2_PrevStMdl,Rsq_RespMdl)
  return(OpTab)
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Fn 4: #This function takes the list of files in the directory (FilesToLoad), a string identifying the target speaker and responder (RespToSpkr;
#eg. ANRespToCHNSP), a string identifying the condition associated with the prev-to-prev IVI control (whether the prev-to-prev IVI control terms should
#be (Prev2IVI) or. (Prev2IVI + prevIVI) (Prev2Var_Cond; as, respectively, 'not_sum' and 'sum'), and the confidence interval level to compute confidence 
#intervals, and performs the two-step response effect analysis controlling for the effect of any intrinsic vocalisation pattern of the target 
#speaker (by regressing current IVI against prev IVI and the effect of the prev-to-prev IVI; see below), and outputs the results of stastitical 
#analyses as a tibble. Note that here, we are only doing the analyses on IVIs.
#Here, we implement two steps: get the previous IVI + previous 2 IVIs beta values, and then, response effect beta values based on residuals of the 
#Current IVI ~ Previous IVI + (Prev2IVI control term) analyses. Note that this is done in two steps because the 
#CurrStepSi ~ PrevStSi + (Prev2IVI control term) analyses are carried out on all non-NaN steps, but the response analyses are only done 
#on steps associated with non-NA responses
#The third input is CILvl, which is the desired confidence level to compute confidence interval in the form of <percent/100>. That is, for 95% confidence intervals, 
#CILvl = 0.95 (correponding to a p-value alpha threshold = 0.05) and so on and so forth. NOTE THAT in the master function WriteOpToFile_RespEffBetas, CILvl is 
#specified as a percent value (i.e., 95 instead 0.95, in the example given here), and that value gets converted to <percent/100> before passing on to these functions.
#Note also that this function implements the protocol for validation data: human-listener labelled 5-minute sections and the corresaponding LENA labelled sections,
#by using age and age:id interaction as random effects (since age isn't an axis along which there is much variation--and we aren't interested in that for
#the validation data)
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GetRespEff_IVI_w_Prev2StSiCtrl_ValData <- function(FilesToLoad,RespToSpkr,CILvl,Prev2Var_Cond){
  
  InfAge_Months <- c(); RespWin_Seconds <- c() #initialise vectors to iteratively store output in (we don't need InfAge_Months, but we are going to concatenate 
  #the validation and LENA tables, so we have this for consistency)
  PrevSt_Beta <- c(); PrevStP <- c(); PrevStCI_Lwr <- c(); PrevStCI_Upper <- c()
  Prev2St_Beta <- c(); Prev2StP <- c(); Prev2StCI_Lwr <- c(); Prev2StCI_Upper <- c()
  Response_Beta <- c(); ResponseP <- c(); ResponseCI_Lwr <- c(); ResponseCI_Upper <- c()
  NumObs_PrevStMdl <- c(); NumObs_RespMdl <- c(); 
  MargR2_PrevStMdl <- c(); CondR2_PrevStMdl <- c(); #note that teh marginal Rsq is the proportion of variance explained by the
  #fixed effects only while the conditional Rsq is the proportion of variance explained by the fixed and random effects combined
  Rsq_RespMdl <- c(); #Because the response model is always a simple IEI residual ~ response variable linear model, we don't report
  #adjusted rsq
  Ctr <- 0; #initialise counter variable
  
  for (i in FilesToLoad){ #go through file list
    if (str_contains(i,RespToSpkr)){ #check if file name has the target string
      
      DataTab <- read_csv(i); attach(DataTab) #read table
      RespWindowVals <- gsub('Response_','',colnames(DataTab)[1]) #get response window values: the first of the data table is the 5 s response window
      #(but keeping the structure that allows for looping through multiple response window values so the functionality exists)
      
      #NOTE that we are NOT subsetting for age
      ID <- as_factor(DataTab$InfantID); AgeVar <- scale(DataTab$AgeMonths) #get ID and age
      CurrVar <- log10(DataTab$CurrIVI + (10^-10)); PrevVar <- log10(DataTab$PrevIVI + (10^-10)); #log current and previous IVIs
      #log (prev + prev-to-prev) IVI: we can either use (Prev2IVI) or (PrevIVI + Prev2IVI) as the explanatory variable. The if statement below 
      #accounts for these options
      if (strcmp(Prev2Var_Cond,'sum')){
        Prev2Var <- log10(DataTab$PrevIVI + DataTab$Prev2IVI + (10^-10)) 
      } else if (strcmp(Prev2Var_Cond,'not_sum')){
        Prev2Var <- log10(DataTab$Prev2IVI + (10^-10))
      } else {
        stop('Prev-to-prev IVI condition should be either sum or no_sum')
      }
      
      for (j in 1:numel(RespWindowVals)){ #Go through the different response windows
        #We are only considering resp win = 5 s (but keeping the structure that allows for looping through multiple response window 
        #values so the functionality exists)
        
        fprintf('\n')
        fprintf('-------------------------------------------------------------------------------------------------------------\n')
        fprintf('File being analysed: %s; response type: %s; response window value = %s seconds (infant 
                ages are pooled together for validations data) \n',i, RespToSpkr, RespWindowVals[j])
        
        #print(j)
        Ctr <- Ctr + 1 #update Ctr
        
        #run just prev var model and get residuals
        LmerMdl_PrevSt <- lmer(scale(CurrVar) ~ (1|ID) + (1|AgeVar) + (1|AgeVar:ID) + scale(PrevVar) + scale(Prev2Var),na.action=na.exclude)
        PrevStSummary <- summary(LmerMdl_PrevSt); PrevStCIs <- confint(LmerMdl_PrevSt,level = CILvl)
        PrevStMdlRsq <- r2(LmerMdl_PrevSt) #estimates marginal and conditional Rsq
        ResidVar <- resid(LmerMdl_PrevSt)
        
        fprintf('Previous IEI control model results: \n')
        print(PrevStSummary)
        fprintf('\n')
        fprintf('Previous IEI control confidence intervals: \n')
        print(PrevStCIs)
        
        TabForLm <- tibble(ResidVar,DataTab[,j]) #get table for linear model so we can subset only non-NaN responses; Note that for the response vector, we just index the get j-th response vector from DataTab
        #for j-th response window value. Indexing this way makes it so that the column name from DataTab is preserved
        colnames(TabForLm)[2] <- 'CurrRespVar' #rename the second column to a standard name as opposed to the preserved column name from Data
        LmSubsetTab <- filter(TabForLm,!is.nan(CurrRespVar)) #filter for non-NaN repsonse values ONLY
        ResponseForLm <- as_factor(LmSubsetTab$CurrRespVar) 
        
        #run response effect on residuals
        LmMdl_Resp <- lm(scale(LmSubsetTab$ResidVar) ~ ResponseForLm) #+ poly(Age,2,raw = TRUE) + poly(Age,2,raw = TRUE)*ResponseForLm)
        RespSummary <- summary(LmMdl_Resp); RespCIs <- confint(LmMdl_Resp,level = CILvl)
        
        fprintf('Response effect model results: \n')
        print(RespSummary)
        fprintf('\n')
        fprintf('Response effect confidence intervals: \n')
        print(RespCIs)
        
        #store results
        RespWin_Seconds[Ctr] <- as.numeric(RespWindowVals[j]); InfAge_Months[Ctr] <- NA
        NumObs_PrevStMdl[Ctr] <- nobs(LmerMdl_PrevSt); NumObs_RespMdl[Ctr] <- nobs(LmMdl_Resp)
        MargR2_PrevStMdl[Ctr] <- PrevStMdlRsq$R2_marginal; CondR2_PrevStMdl[Ctr] <- PrevStMdlRsq$R2_conditional
        Rsq_RespMdl[Ctr] <- RespSummary$r.squared
        
        PrevSt_Beta[Ctr] <- PrevStSummary$coefficients[2,1] 
        PrevStP[Ctr] <- PrevStSummary$coefficients[2,5] 
        PrevStCI_Lwr[Ctr] <- PrevStCIs[6,1]
        PrevStCI_Upper[Ctr] <- PrevStCIs[6,2]
        
        Prev2St_Beta[Ctr] <- PrevStSummary$coefficients[3,1]
        Prev2StP[Ctr] <- PrevStSummary$coefficients[3,5]
        Prev2StCI_Lwr[Ctr] <- PrevStCIs[7,1]
        Prev2StCI_Upper[Ctr] <- PrevStCIs[7,2]
        
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
                  Prev2St_Beta,Prev2StP,Prev2StCI_Lwr,Prev2StCI_Upper,
                  Response_Beta,ResponseP,ResponseCI_Lwr,ResponseCI_Upper,
                  NumObs_PrevStMdl, NumObs_RespMdl,
                  MargR2_PrevStMdl, CondR2_PrevStMdl,Rsq_RespMdl)
  return(OpTab)
}

