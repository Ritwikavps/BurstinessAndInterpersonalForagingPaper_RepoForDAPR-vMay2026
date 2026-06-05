# Ritwika VPS, Dec 2025
# This script was written in response to reviewer comments to investigate the effect of controlling for the previous as well as the prvious-to-previous
# IEIs. 

##This script takes data tables with current and previous IVIs, for each recording day at different rersponse window thresholds, and gets the
#beta values for previous and prev-to-previous step size effect and response effect at the corpus level. The prev-to-prev IVI additional term 
#can either be (Prev2IVI) or (PrevIVI + Prev2IVI), which is controlled using a string input (Prev2Var_Cond)This is done for LENA day-long data, 
#human-listener labelled 5 min sections, and corresponding LENA 5 min sections. All model outputs are also written into a sink file.

#load required librarues
library(lme4); library(lmerTest); library(pracma); library(sjmisc); library(tidyverse); library(performance) #to compute Rsq for lmer
#ref: A general and simple method for obtaining R2 from generalized linear mixed-effects models. Nakagawa and Holger 

#source necessary functions
source('~/Desktop/GoogleDriveFiles/research/IVFCRAndOtherWorkWithAnne/Pre_registration_followu/CodeForGitHub/A4_DataAnalysis/A1_ResponseAnalyses_IEIs/RevFn_GetLmerCoeffsForResponseBetas_w_Prev2StSizeCtrl_5sRespWin.R')

FilePattern <- '.*IviOnly.csv' #this is the string to pick out relevant files (See user-deifned fn WriteOpToFile_RespEffBetas for details)
CILvl <- 99.9 #specify desired confidence interval in the form of a percent value. That is, for 95% confidence intervals, CILvl = 95 (correponding to 
# a p-value alpha threshold = 0.05) and so on and so forth
CIStr <- gsub('\\.','_',strcat(as.character(CILvl),'prc')) #convert the CILvl to a string, add 'prc' to signify percent, then sub the decimal point ('.')
WriteOpPath <- '~/Desktop/GoogleDriveFiles/research/IVFCRAndOtherWorkWithAnne/Pre_registration_followu/Data/ResultsTabs/ResponseAnalyses/'
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#LENA day-long files
WorkingDir_LENA <- '~/Desktop/GoogleDriveFiles/research/IVFCRAndOtherWorkWithAnne/Pre_registration_followu/Data/ResultsTabs/ResponseAnalyses/ResponseEffect_w_CurrPrevStSizeControl_LENA/CurrPrev2StSize_5sRespWin_IviOnly_LENA/'
DataType_LENA <- 'LENA'

#LENA 5 min matched files
WorkingDir_LENA5min <- '~/Desktop/GoogleDriveFiles/research/IVFCRAndOtherWorkWithAnne/Pre_registration_followu/Data/ResultsTabs/ResponseAnalyses/ResponseEffect_w_CurrPrevStSizeControl_LENA5min/CurrPrev2StSize_5sRespWin_IviOnly_LENA5min/'
DataType_LENA5min <- 'LENA5min'

#human listener labelled files: all adult utterances
WorkingDir_Hum_AllAd <- '~/Desktop/GoogleDriveFiles/research/IVFCRAndOtherWorkWithAnne/Pre_registration_followu/Data/ResultsTabs/ResponseAnalyses/ResponseEffect_w_CurrPrevStSizeControl_H/CurrPrev2StSize_5sRespWin_IviOnly_H/'
DataType_Hum_AllAd <- 'Hum-AllAd'

#human listener labelled files with child directed AN utterances only
WorkingDir_Hum_ChildDirAd <- '~/Desktop/GoogleDriveFiles/research/IVFCRAndOtherWorkWithAnne/Pre_registration_followu/Data/ResultsTabs/ResponseAnalyses/ResponseEffect_w_CurrPrevStSizeControl_H_ChildDirANOnly/CurrPrev2StSize_5sRespWin_IviOnly_H_ChildDirANOnly/'
DataType_Hum_ChildDirAd <- 'HumChildDirAdOnly'

#put together lists for working directories and data types
WorkingDir <- c(WorkingDir_LENA,  WorkingDir_LENA5min,  WorkingDir_Hum_AllAd,   WorkingDir_Hum_ChildDirAd)
DataType <- c(DataType_LENA,      DataType_LENA5min,    DataType_Hum_AllAd,     DataType_Hum_ChildDirAd)

#details of previous 2 IEI control: 'not_sum' is for model choice of ~ Prev_IEI + Prev_2IEI; 'sum' is for ~ Prev_IEI + (Prev_IEI + Prev_2IEI)
Prev2Var_Cond = 'not_sum' #(can be 'sum' or 'not_sum')
PrevStSiCtrlorNo = 'w2Ctrl'

#open sink file to write all console output
SinkFileName = paste(WriteOpPath,'Rev_RespEff_W_Prev2StSizCtrl_',Prev2Var_Cond,
                     '_5sRespWin_VarsScaleLog_CorpusLvl_IviOnly_CI',CIStr,'_ModelResultsDetails.txt',sep='')
sink(SinkFileName)
WriteOpToFile_RespEffBetas_2PrevStSizeCtrl(WorkingDir,FilePattern,DataType,WriteOpPath,PrevStSiCtrlorNo,CILvl,Prev2Var_Cond)

sink() #close sink




