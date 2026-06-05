clear; clc

%This script plots a 4-panel figure with infant and adult response betas with or without the step size control as specified (WithOrWoCtrlTxt), for different ages and response windows 
% using the custom function GetRespBetaFigs. This script does this for LENA day-long data, as well as the validation data.

LENA_AgeClrs = [0 0 0 ; 126 3 168;    204 71 120;  248  149 64]/256; %line colours for the LENA data for each age
ValDataClrs = [119 39 89; 63 139 156; 163 179 96]/256; %line colours for each data type

%read in data table
Basepath = '~/BaseDataPath/Data/ResultsTabs/ResponseAnalyses/';
cd(Basepath)
wCtrlTab = readtable('RespEff_W_PrevStSizCtrl_VarsScaleLog_CorpusLvl_IviOnly_CI99_9prc.csv'); %results from with control tests
woCtrlTab = readtable('RespEff_NoPrevStSizCtrl_VarsScaleLog_CorpusLvl_IviOnly_CI99_9prc.csv'); %results from without control tests

%specify validation data strings as well as corresponding legend strings
ValDataTypeList = {'LENA5min','Hum-AllAd','HumChildDirAdOnly'}; ValDataLegend = {'L: 5 min','H: All Adult','H: Child-directed Adult'};

%Plot (for details of the inputs, see the user-defined function)!!
GetRespBetaFigs(wCtrlTab,LENA_AgeClrs,ValDataTypeList,ValDataClrs,ValDataLegend,'w/ ctrl','MainTxt')
%GetRespBetaFigs(wCtrlTab,LENA_AgeClrs,ValDataTypeList,ValDataClrs,ValDataLegend,'w/ ctrl','SI')
%GetRespBetaFigs(woCtrlTab,LENA_AgeClrs,ValDataTypeList,ValDataClrs,ValDataLegend,'w/o ctrl','SI')

GetRespBetaFigs_SI(wCtrlTab,woCtrlTab,LENA_AgeClrs,ValDataTypeList,ValDataClrs,ValDataLegend,'LENA','SI')
GetRespBetaFigs_SI(wCtrlTab,woCtrlTab,LENA_AgeClrs,ValDataTypeList,ValDataClrs,ValDataLegend,'ValData','SI')