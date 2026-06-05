clear; clc

% This script goes through all 3 sets of daat (LENA day-long, human label 5 min, and corresponding LENA 5 min) and merges vocs of a given speaker type separated by 0 IVI. 
% Note that we treat CHNSP, CHNNSP, and AN (both FAN and MAN together) speaker types differently.
%
% NOTE THAT WE DO THIS FOR ALL FILES, EVEN THOSE THAT ARE NOT AT AGES 3, 6, 9, or 18 MONTHS.
% Also note that the numbers reported and saved here are the total number of merge events, where two vocs being merged is one event, regardless of whether more vocs are going to be merged
% to get to the final merged voc. So, if 4 vocs are merged to get one voc, this would count as 3 merge events, for example.

%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLEASE CHANGE PATHS AND STRINGS IN FUNCTION CALL APPROPRIATELY
BasePath = '~/BaseDataPath/Data/';%This is the base path to the google drive folder that may undergo change
%read in table with .its file details
cd(strcat(BasePath,'MetadataFiles/'));
opts = detectImportOptions('MergedTSAcousticsMetadata.csv'); %make sure to read in infant code as string
opts = setvartype(opts, 'InfantID', 'string');
MetadataTab = readtable('MergedTSAcousticsMetadata.csv',opts);

%LENA (day-long) specific inputs; 
LENA_ZscoreDataPath = strcat(BasePath,'LENAData/A7_ZscoredTSAcousticsLENA/');
LENA_DestinationPath = strcat(BasePath,'LENAData/A8_NoAcoustics_0IviMerged_LENA/');
LENA_StringToRemoveFromFname = '_ZscoredAcousticsTS_LENA.csv';
LENA_StringToAddToFname = '_NoAcoustics_0IviMerged_LENA.csv';

%human listener labelled data specific inputs
H_ZscoreDataPath = strcat(BasePath,'/HUMLabelData/A2_HUMLabelData_PostCleanUp/A7_HlabelTS_Zscored/');
H_DestinationPath_AllANUtts = strcat(BasePath,'/HUMLabelData/A2_HUMLabelData_PostCleanUp/A9_NoAcoustics_0IviMerged_Hum/');
H_StringToRemoveFromFname = '_ZscoredAcousticsTS_Hum.csv';
H_StringToAddToFname_AllANUtts = '_NoAcoustics_0IviMerged_Hum.csv';
%additional human listener labelled data specific inputs: child-directed adult utterances ONLY.
H_DestinationPath_ChildDirANUtts = strcat(BasePath,'/HUMLabelData/A2_HUMLabelData_PostCleanUp/A11_NoAcoustics_0IviMerged_Hum_ChildDirANOnly/');
H_StringToAddToFname_ChildDirANUtts = '_NoAcoustics_0IviMerged_ChildDirANOnly_Hum.csv';

%match ed 5 min LENA data specific inputs
LENA_5min_ZscoreDataPath = strcat(BasePath,'/HUMLabelData/A2_HUMLabelData_PostCleanUp/A8_MatchedLENAZscoreSections/');
LENA_5min_DestinationPath = strcat(BasePath,'/HUMLabelData/A2_HUMLabelData_PostCleanUp/A10_NoAcoustics_0IviMerged_L5min/');
LENA_5min_StringToRemoveFromFname = '_MatchedLENA_ZscoreTS.csv';
LENA_5min_StringToAddToFname = '_NoAcoustics_0IviMerged_LENA5min.csv';

PathCell = {LENA_ZscoreDataPath, H_ZscoreDataPath, H_ZscoreDataPath, LENA_5min_ZscoreDataPath}; %put all three sets of inputs (path, destination path, etc.) into a cell array so we can loop and
%parallelise the thing
DestinationCell = {LENA_DestinationPath, H_DestinationPath_AllANUtts, H_DestinationPath_ChildDirANUtts, LENA_5min_DestinationPath};
StringToRemoveCell = {LENA_StringToRemoveFromFname, H_StringToRemoveFromFname, H_StringToRemoveFromFname, LENA_5min_StringToRemoveFromFname};
StringToAddCell = {LENA_StringToAddToFname, H_StringToAddToFname_AllANUtts, H_StringToAddToFname_ChildDirANUtts, LENA_5min_StringToAddToFname};
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%do for all three labelling methoids
p = parpool(4);
parfor i = 1:numel(PathCell)
    Save0IviMerged_NoAcousticsTabs(PathCell{i},DestinationCell{i},StringToRemoveCell{i},StringToAddCell{i},MetadataTab,BasePath) 
end
delete(p)
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function [] = Save0IviMerged_NoAcousticsTabs(ZscorePath,DestinationPath,StringToRemoveFromFname,StringToAddToFname,MetadataTab,BasePath)

    %this function reads in all files from the given directory (ZscoreDir), removes acoustics (pitch, amplitude, and duration), and merges all vocs of a given speaker type that 
    % are separated by 0 IVI. Then, these new tables as well a table with details of how many voc merges were performed for each speaker type (FAN and MAN treated as a single 
    % AN type) are saved.

    %Get Zscored data
    cd(ZscorePath); ZscoreDir = dir(strcat('*',StringToRemoveFromFname));

    for i = 1:numel(ZscoreDir) %go through list of files
    
        ZscoreFnRoot = erase(ZscoreDir(i).name, StringToRemoveFromFname); % get the root of the filename
        ZscoreTab = readtable(ZscoreDir(i).name,'Delimiter',',');
        if contains(StringToAddToFname,'ChildDirANOnly') %if this is meant to be a subset of adult utterances (either ONLY child-directed or T and N types)
            ZscoreTab = ZscoreTab(~contains(ZscoreTab.Annotation,{'U','N'}),:); %ONLY keep child directed adult utterances (so, remove adult utterances annotated U or N)
        end
        
        [MergedTab, TotalMergeCt_AN(i,1),TotalMergeCt_CHNSP(i,1),TotalMergeCt_CHNNSP(i,1)] = MergeZeroIviVocsAndGetTSOnlyTab(ZscoreTab);
    
        if isempty(MergedTab) %if table is empty
            TotalMergeCt_AN(i,1) = NaN;
            TotalMergeCt_CHNSP(i,1) = NaN;
            TotalMergeCt_CHNNSP(i,1) = NaN;
        end
    
        %get infant id and age
        InfantID{i,1} = MetadataTab.InfantID(contains(MetadataTab.FileNameRoot,ZscoreFnRoot));
        InfantAgeMonth(i,1) = MetadataTab.InfantAgeMonth(contains(MetadataTab.FileNameRoot,ZscoreFnRoot));

        if size(MergedTab,1) ~= 0 %if the Ivi merged tab isn't empty, save
            FileNameToSave_StepSiTab = strcat(DestinationPath,ZscoreFnRoot,StringToAddToFname);
            writetable(MergedTab,FileNameToSave_StepSiTab)
        end
    end

    MergeDetailsTab = table(InfantID,InfantAgeMonth,TotalMergeCt_CHNNSP,TotalMergeCt_CHNSP,TotalMergeCt_AN); %put together table with merge details
    if contains(StringToAddToFname,'LENA5min') %get label method info
        LabelMethod = 'LENA5min';
    elseif contains(StringToAddToFname,'0IviMerged_Hum')
        LabelMethod = 'HumAllANUtts';
    elseif contains(StringToAddToFname,'ChildDirANOnly')
        LabelMethod = 'HumChildDirANOnly';
    elseif contains(StringToAddToFname,'LENA') && ~contains(StringToAddToFname,'5min')
        LabelMethod = 'LENA';
    end
    writetable(MergeDetailsTab,strcat(BasePath,'MetadataFiles/ZeroIviMergeDetailsTab_',LabelMethod,'.csv')) %save table
    %----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    %I like to move this table to the folder MetaDataFiles (but I do that manually. PLEASE MAKE SURE to do this after running this script (or change paths in any future scripts accordingly).
    %----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
end
