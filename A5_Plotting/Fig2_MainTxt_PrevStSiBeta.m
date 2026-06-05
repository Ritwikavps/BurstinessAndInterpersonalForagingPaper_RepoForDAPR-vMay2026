clear; clc

%This script plots a figure with infant and adult prev. step size betas for different ages using the custom function GetPrevStSizeBetaFig_LENA.m and GetPrevStSizeBetaFig_SI.m.
% This script does this for LENA day0long data, LENA 5 min data, and human-labelled 5 min data, by specifiying the input string and path

LENAClrs = [0 0.4470 0.7410; 0 0 0]; %first colour is for CHNSP, the second is for AN
ValDataClrs = [119 39 89; 63 139 156; 163 179 96]/256; %line colours for each data type

ValDataTypeList = {'LENA5min','Hum-AllAd','HumChildDirAdOnly'};
ValDataLegend = {'L: 5 min','H: All Adult','H: Child-directed Adult'};

Basepath = '~/BaseDataPath/Data/ResultsTabs/ResponseAnalyses/';
cd(Basepath)
wCtrlTab = readtable('RespEff_W_PrevStSizCtrl_VarsScaleLog_CorpusLvl_IviOnly_CI99_9prc.csv');

GetPrevStSiEffFig(wCtrlTab,LENAClrs,ValDataClrs,ValDataTypeList,ValDataLegend)
