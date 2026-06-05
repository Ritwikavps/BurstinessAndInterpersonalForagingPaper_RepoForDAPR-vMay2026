#@author info, Feb 2024
#This script generates the data to plot data viz schematics plots in Fig 1: the Curr IVI vs Prev IVI plot as well as the WR/WOR residuals plot. Note that this 
#function does this for all data we have (LENA day-long, LENA 5 min, human listener labelled 5 minute with child directed adult voc ONLY, and human liostener
#labelled 5 min data with all adult vocs; and ANRespToCHNSP and CHNSPRespToAN for all these data types), at the recording day level

library(tidyverse); library(lme4); library(pracma); library(sjmisc); #get libraries
#source user-defined function
source('~/BaseCodePath/CodeForGitHub/A4_DataAnalysis/A1_ResponseAnalyses_IEIs/GetPrevStCtrlResids_RecLvl.R')

FilePattern <- '.*IviOnly.csv' #this is the string to pick out relevant files (See user-deifned fn WriteOpToFile_RespEffBetas for details)
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

WriteResidsToFile_RecLvl(WorkingDir,FilePattern,DataType,WriteOpPath)




