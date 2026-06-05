#@author info
#This script takes data tables with current and previous IVIs, for each recording day at different rersponse window thresholds, and gets the
#age effects on prev step size beta as well as response betas with and without the prev step size control, using a quadratic lmer model

#load required librarues
library(lme4); library(lmerTest); library(pracma); library(sjmisc); library(tidyverse)

#source necessary functions
source("~/BaseCodePath/CodeForGitHub/A4_DataAnalysis/A1_ResponseAnalyses_IEIs/GetLmerCoeffsForAgeEffects.R")

FilePattern <- '.*IviOnly.csv' #this is the string to pick out relevant files (See user-deifned fn WriteOpToFile_RespEffBetas for details)
CILvl <- 99.9 #specify desired confidence interval in the form of a percent value. That is, for 95% confidence intervals, CILvl = 95 (correponding to 
# a p-value alpha threshold = 0.05) and so on and so forth
WriteOpPath <- '~/BaseDataPath/Data/ResultsTabs/ResponseAnalyses/'
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#LENA day-long files
WorkingDir_LENA <- '~/BaseDataPath/Data/ResultsTabs/ResponseAnalyses/ResponseEffect_w_CurrPrevStSizeControl_LENA/'
DataType_LENA <- 'LENA'

#LENA 5 min matched files
WorkingDir_LENA5min <- '~/BaseDataPath/Data/ResultsTabs/ResponseAnalyses/ResponseEffect_w_CurrPrevStSizeControl_LENA5min/'
DataType_LENA5min <- 'LENA5min'

#human listener labelled files: all adult utterances
WorkingDir_Hum_AllAd <- '~/BaseDataPath/Data/ResultsTabs/ResponseAnalyses/ResponseEffect_w_CurrPrevStSizeControl_H/'
DataType_Hum_AllAd <- 'Hum-AllAd'

#human listener labelled files with child directed AN utterances only
WorkingDir_Hum_ChildDirAd <- '~/BaseDataPath/Data/ResultsTabs/ResponseAnalyses/ResponseEffect_w_CurrPrevStSizeControl_H_ChildDirANOnly/'
DataType_Hum_ChildDirAd <- 'HumChildDirAdOnly'

#put together lists for working directories and data types
WorkingDir <- c(WorkingDir_LENA,  WorkingDir_LENA5min,  WorkingDir_Hum_AllAd,   WorkingDir_Hum_ChildDirAd)
DataType <- c(DataType_LENA,      DataType_LENA5min,    DataType_Hum_AllAd,     DataType_Hum_ChildDirAd)

RecLvlBetasTab <- GetRecLvlBetasFinalTabAndWriteToFile(WorkingDir,FilePattern,DataType,WriteOpPath) #get recording level betas and save table
GetLmerAgeEffOnRespBetaAndWriteOpToFile(RecLvlBetasTab,CILvl,WriteOpPath) #get age effects based on recording level betas

