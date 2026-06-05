clear; clc
% Ritwika VPS, Dec 2025
% This is part of additional analyses code being written for the Burstiness paper in response to reviewer comments (however, I am preserving the 'step size' language as 
% opposed to IEI in function names etc for continuity with the rest of the code. Note that we only do these analyses for the 5 s response window for illustrative purposes.

% This script and associated functions take vocalisation data, compute response recived or not for a specified response interval, and output 
% current step size, previous step size, whether current step is WOR or WR, and writes the table for further statsitical analyses

%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLEASE CHANGE PATHS AND STRINGS IN FUNCTION CALL APPROPRIATELY
BasePath = '~/Desktop/GoogleDriveFiles/research/IVFCRAndOtherWorkWithAnne/Pre_registration_followu/Data/';%This is the base path to the google drive folder that may undergo change
%read in table with .its file details
cd(strcat(BasePath,'MetadataFiles/'));
opts = detectImportOptions('MergedTSAcousticsMetadata.csv'); %make sure to read in infant code as string
opts = setvartype(opts, 'InfantID', 'string');
MetadataTab = readtable('MergedTSAcousticsMetadata.csv',opts);

%(Note that these are no longer paths to z-scored data; the names are merely relics of older exploratory analyses).
%LENA (day-long) specific inputs; 
LENA_ZscoreDataPath = strcat(BasePath,'LENAData/A8_NoAcoustics_0IviMerged_LENA/');
LENA_DestinationPath = strcat(BasePath,'ResultsTabs/ResponseAnalyses/ResponseEffect_w_CurrPrevStSizeControl_LENA/CurrPrev2StSize_5sRespWin_IviOnly_LENA/');
LENA_StringToRemoveFromFname = '_NoAcoustics_0IviMerged_LENA.csv';

%human listener labelled data specific inputs: all adult vocs included (T, U, N)
H_ZscoreDataPath = strcat(BasePath,'/HUMLabelData/A2_HUMLabelData_PostCleanUp/A9_NoAcoustics_0IviMerged_Hum/');
H_DestinationPath = strcat(BasePath,'ResultsTabs/ResponseAnalyses/ResponseEffect_w_CurrPrevStSizeControl_H/CurrPrev2StSize_5sRespWin_IviOnly_H/');
H_StringToRemoveFromFname = '_NoAcoustics_0IviMerged_Hum.csv';

%human listener labelled data specific inputs: ONLY child directed adult vocs included.
H_ZscoreDataPath_ChnDirAnOnly = strcat(BasePath,'/HUMLabelData/A2_HUMLabelData_PostCleanUp/A11_NoAcoustics_0IviMerged_Hum_ChildDirANOnly/');
H_DestinationPath_ChnDirAnOnly = strcat(BasePath,'ResultsTabs/ResponseAnalyses/ResponseEffect_w_CurrPrevStSizeControl_H_ChildDirANOnly/CurrPrev2StSize_5sRespWin_IviOnly_H_ChildDirANOnly/');
H_StringToRemoveFromFname_ChnDirAnOnly = '_NoAcoustics_0IviMerged_ChildDirANOnly_Hum.csv'; 

%matched 5 min LENA data specific inputs
LENA_5min_ZscoreDataPath = strcat(BasePath,'/HUMLabelData/A2_HUMLabelData_PostCleanUp/A10_NoAcoustics_0IviMerged_L5min/');
LENA_5min_DestinationPath = strcat(BasePath,'ResultsTabs/ResponseAnalyses/ResponseEffect_w_CurrPrevStSizeControl_LENA5min/CurrPrev2StSize_5sRespWin_IviOnly_LENA5min/');
LENA_5min_StringToRemoveFromFname = '_NoAcoustics_0IviMerged_LENA5min.csv';
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%put paths etc into cell arrays
PathCell = {LENA_ZscoreDataPath,LENA_5min_ZscoreDataPath, H_ZscoreDataPath, H_ZscoreDataPath_ChnDirAnOnly};
DestinationPathCell = {LENA_DestinationPath,LENA_5min_DestinationPath,H_DestinationPath,H_DestinationPath_ChnDirAnOnly};
StrToRemoveCell = {LENA_StringToRemoveFromFname,LENA_5min_StringToRemoveFromFname,H_StringToRemoveFromFname,H_StringToRemoveFromFname_ChnDirAnOnly};

%This is currently set up such that we are only looking at CHNSP responses to AN, and AN responses to CHNSP; but the scope of this can be expanded to
%other utterance types, eg. AN responses to all CHN utterances, etc
SpkrType = {'AN','CHNSP'};
OtherType = {'CHNSP','AN'};
NAType = {'AN','CHN'};

%ResponseWindow = 1:10; %specify response window
%ResponseWindow = [0.5 ResponseWindow]; %add a 0.5 second response window 
ResponseWindow = 5;  %only for 5 second response window

%p = parpool(4); %open parallel pool

for i = 1:numel(PathCell)%get outputs for LENA day-long, human-listener labelled, and matched LENA 5 min data
    DataType = erase(erase(StrToRemoveCell{i},'_NoAcoustics_0IviMerged_'),'.csv');
    disp(strcat('Starting ',DataType))
    ComputeCurrPrev2StSizeTabAndSave(PathCell{i},DestinationPathCell{i},StrToRemoveCell{i},...
                                                                SpkrType,OtherType,NAType,ResponseWindow,MetadataTab)
    disp(strcat('Ending ',DataType))
end

%delete(p) %delete parallel pool
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%this function generates and saves the data tables to do the curr-prev step size control response analyses for response windows of 1 to 10 s, for AN speakers (CHNSP) response, 
% and CHNSP speakers (AN response)
function [] = ComputeCurrPrev2StSizeTabAndSave(ZscoreDataPath,DestinationPath,StringToRemoveFromFname,...
                                                                SpkrType,OtherType,NAType,ResponseWindow,MetadataTab)


%Inputs: - ZscoreDataPath: path with z-scored acoustics and time series data
        %- DestinationPath: path to save results data tables
        %- StringToRemoveFromFname: the specific string to remove from the z-scored file names to get the file name root
        %- SpkrType, OtherType, NAType: the cell arrays with the list of speakers of interest, responders, as well as the speaker tag that triggers an NA response.
            %So, if the i-th combination of speaker and responder is AN responses to CHNSP, then SpkrType{i} = CHNSP, OtherType{i} = AN, and NAType{i} = CHN.
            % This is because for AN responses to CHNSP, both CHNSP and CHNNSP triggers an NA response.
        %- ResponseWindow: the vector of response window values
        %- MetadataTab: table with metadata

    cd(ZscoreDataPath); ZscoreDir = dir(strcat('*',StringToRemoveFromFname)); %Get Zscored data
    
    for i = 1:numel(OtherType) %loop for OtherType (since the index for each OtherType speaker tag serves as the index for the corresponding Speaker and responder type, we only need
        %to index for one of these three vectors, in the for loop
        [OpTab] = RevFn_GetTabForLmer_CurrPrev2StSize_IviOnly(ZscoreDir,ResponseWindow, SpkrType{i}, OtherType{i}, NAType{i}, StringToRemoveFromFname, MetadataTab); %get aggregated table with
        %current and prev step size info for each recording, as well as infant id and age details, for each combo of <Responder>_response to_<speaker> and response window

        DataType = erase(erase(StringToRemoveFromFname,'_NoAcoustics_0IviMerged_'),'.csv');
        FileNameToSave_StepSiTab = strcat(DestinationPath,'CurrPrev2StSize_',DataType,'_',OtherType{i},'RespTo',SpkrType{i},'_5sRespWin_IviOnly.csv');
        writetable(OpTab,FileNameToSave_StepSiTab)     
    end
end