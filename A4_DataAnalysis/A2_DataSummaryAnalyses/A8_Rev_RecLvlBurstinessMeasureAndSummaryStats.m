clear; clc

%Ritwika VPS, UCLA Comm, Dec 2025

% This script is written as part of supplemental analysis done re: revision for the Burstiness paper following ProcB reviews. Here, I take the IEIs (CHNSP and AN) for all data
% types (LENA daylong + validation data), compute the burstiness measure as reported in "Advancing a temporal science of behavior, Abney et al, 2025" (which was originally
% proposed in "Burstiness and memory in complex systems, Goh and Barabasi, 2008") for all recordings/files with the following considerations in mind:
    % - when calculating the burstiness measure for IEI series pooled from multiple subrecs or 5-min sections, keep in mind that this is essentially sub-sampling 
        % daylong data. Also note that this script plops together IEIs across different subrecordins/5-minute sections, but DOES not compute IEIs from the end
        % of one subrec/5-min section to the next.
    % - the burstiness measure may not be meaningful for very small sample sizes (We set this threshold to be 10 IEIs)

%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLEASE CHANGE PATHS AND STRINGS IN FUNCTION CALL APPROPRIATELY
BasePath = '/Users/ritwikavps/Desktop/GoogleDriveFiles/research/IVFCRAndOtherWorkWithAnne/Pre_registration_followu/Data/';%This is the base path to the google drive folder that may undergo change
%read in table with .its file details
cd(strcat(BasePath,'MetadataFiles/'));
opts = detectImportOptions('MergedTSAcousticsMetadata.csv'); %make sure to read in infant code as string
opts = setvartype(opts, 'InfantID', 'string');
MetadataTab = readtable('MergedTSAcousticsMetadata.csv',opts);

DestinationPath = strcat(BasePath,'ResultsTabs/DataDescriptionSummaries/'); %Destination path

%(Note that these are no longer paths to z-scored data; the names are merely relics of older exploratory analyses).
%LENA (day-long) specific inputs; 
LENA_ZscoreDataPath = strcat(BasePath,'LENAData/A8_NoAcoustics_0IviMerged_LENA/');
LENA_StringToRemoveFromFname = '_NoAcoustics_0IviMerged_LENA.csv';

%human listener labelled data specific inputs: all adult vocs included (T, U, N)
H_ZscoreDataPath = strcat(BasePath,'/HUMLabelData/A2_HUMLabelData_PostCleanUp/A9_NoAcoustics_0IviMerged_Hum/');
H_StringToRemoveFromFname = '_NoAcoustics_0IviMerged_Hum.csv';

%human listener labelled data specific inputs: ONLY child directed adult vocs included.
H_ZscoreDataPath_ChnDirAnOnly = strcat(BasePath,'/HUMLabelData/A2_HUMLabelData_PostCleanUp/A11_NoAcoustics_0IviMerged_Hum_ChildDirANOnly/');
H_StringToRemoveFromFname_ChnDirAnOnly = '_NoAcoustics_0IviMerged_ChildDirANOnly_Hum.csv'; 

%match ed 5 min LENA data specific inputs
LENA_5min_ZscoreDataPath = strcat(BasePath,'/HUMLabelData/A2_HUMLabelData_PostCleanUp/A10_NoAcoustics_0IviMerged_L5min/');
LENA_5min_StringToRemoveFromFname = '_NoAcoustics_0IviMerged_LENA5min.csv';
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%put paths etc into cell arrays
PathCell = {LENA_ZscoreDataPath,LENA_5min_ZscoreDataPath, H_ZscoreDataPath, H_ZscoreDataPath_ChnDirAnOnly};
StrToRemoveCell = {LENA_StringToRemoveFromFname,LENA_5min_StringToRemoveFromFname,H_StringToRemoveFromFname,H_StringToRemoveFromFname_ChnDirAnOnly};
DataTypeCell = {'Lday','L5min','H5min','H5min_T_Ad'};

%This is currently set up such that we are only looking at CHNSP responses to AN, and AN responses to CHNSP; but the scope of this can be expanded to
%other utterance types, eg. AN responses to all CHN utterances, etc
SpkrType = {'AN','CHNSP','CHNNSP'};
u_AgeMnths = [3 6 9 18]'; %ages we are interested in

for i = 1:numel(PathCell)

    cd(PathCell{i}); ZscoreDir = dir(strcat('*',StrToRemoveCell{i})); %Get Zscored data files in a structure (to pass to function and read in)
    OpTab = RevFn_GetIEI_BurstinessQt(ZscoreDir,StrToRemoveCell{i},SpkrType,MetadataTab); %get table with burstiness measure at the recording day/validation data file level

    %Get speaker type-level x age-level mean and std deviations for burstiness measure.
    for i_spk = 1:numel(SpkrType)
        for i_age = 1:numel(u_AgeMnths)
            SpkrAge_Tab = OpTab(contains(OpTab.SpeakerType,SpkrType{i_spk}) & OpTab.InfantAgeMonths == u_AgeMnths(i_age),:); 
            SpkrLvlMeanBurstiness(i_age,i_spk) = mean(SpkrAge_Tab.BurstinessQt,'omitnan');
            SpkrLvlStdBurstiness(i_age,i_spk) = std(SpkrAge_Tab.BurstinessQt,'omitnan');
            NumRecs_SpkrLvl(i_age,i_spk) = height(SpkrAge_Tab.BurstinessQt(~isnan(SpkrAge_Tab.BurstinessQt))); %only includerecording day/val data files that have non-NaN B 
            %values for the given speaker type and age.
        end
    end

    %put together the mean/std tab
    MeanStdOpTab = [table(u_AgeMnths) array2table(SpkrLvlMeanBurstiness) array2table(SpkrLvlStdBurstiness) array2table(NumRecs_SpkrLvl)];
    MeanStdOpTab.Properties.VariableNames = ['InfantAgeMonths',strcat('MeanB_',SpkrType),strcat('StdB_',SpkrType),strcat('NumRecs_',SpkrType)]; %get variable names 

    clear SpkrLvlMeanBurstiness SpkrLvlStdBurstiness NumRecs_SpkrLvl

    %write output to table
    writetable(OpTab, strcat(DestinationPath,'RecLvlBurstinessMeasure.xlsx'), 'Sheet', DataTypeCell{i});
    writetable(MeanStdOpTab, strcat(DestinationPath,'RecLvlBurstinessMeasureSummaryStats.xlsx'), 'Sheet', DataTypeCell{i});
end
