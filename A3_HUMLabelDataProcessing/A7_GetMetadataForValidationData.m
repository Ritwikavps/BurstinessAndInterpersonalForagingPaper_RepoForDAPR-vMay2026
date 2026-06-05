clear; clc

%%@author info; Dec 2024; metadata for human-listener labelled data
% (This script -- and this metadata file -- should have been written ages ago, but I never got around to it before this, which is why code from before this point extracts the info that 
% should have been in a validation data metadata file extracts that info in-script).

%Get Lena day-long metadata file
cd('~/BaseDataPath/Data/MetadataFiles/'); %go to required directory
opts = detectImportOptions('MergedTSAcousticsMetadata.csv'); %make sure to read in infant code as string, so get options to read the file
opts = setvartype(opts, 'InfantID', 'string'); %set up opts so that infant id is read in as string
MetadataTab = readtable('MergedTSAcousticsMetadata.csv',opts); %read in file with updated options

%read in list of LENA 5 min files
%(Reading in both the LENA 5 minute data and the human listener labelled 5 min data is simply a check).
L5min_Path = ...
  '~/BaseDataPath/Data/HUMLabelData/A2_HUMLabelData_PostCleanUp/A8_MatchedLENAZscoreSections/';
L5min_DirStr = '*_MatchedLENA_ZscoreTS.csv';
cd(L5min_Path)
L5minDir = dir(L5min_DirStr);

%read in list of Human-listener labelled data (all adult vocs included, by default).
H5min_Path = ...
    '~/BaseDataPath/Data/HUMLabelData/A2_HUMLabelData_PostCleanUp/A7_HlabelTS_Zscored/';
H5min_DirStr = '*_ZscoredAcousticsTS_Hum.csv';
cd(H5min_Path)
H5minDir = dir(H5min_DirStr);

%get metadata tables for L5min and H5min data
L5_MetadataTab = GetvalDataMetadataTab(MetadataTab,L5minDir);
H5_MetadataTab = GetvalDataMetadataTab(MetadataTab,H5minDir);

if ~isequal(L5_MetadataTab,H5_MetadataTab)
    error('L5min and H5min metadata tables are not the same (but should be the same)')
end

%go to directory to write file
cd('~/BaseDataPath/Data/MetadataFiles')
writetable(H5_MetadataTab,'ValDataMergedTSMetaDataTab.csv') %write metadata file

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%Functions used:
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%function to get metadata table.
% 
% Outputs the metadata table for the provided validation dataset
% 
% Inputs: - MetadataTab: metadata file for Lday data
%         - FileDir: relevant list of files.
function ValDataMetadataTab = GetvalDataMetadataTab(MetadataTab,FileDir)
    TempOpTab = array2table(zeros(0,width(MetadataTab))); %initialise temporary table (we will add rows from the day-long metadata table based on the file name of each file in
    %the input validation data directory)
    TempOpTab.Properties.VariableNames = MetadataTab.Properties.VariableNames; %set variable names
    for i = 1:numel(FileDir) %go through list of files
        Curr_FileNameRoot = FileDir(i).name(1:11); %get file name root (first 11 charcaters of the string)
        TempOpTab = [TempOpTab; MetadataTab(contains(MetadataTab.FileNameRoot,Curr_FileNameRoot),:)]; %add relevant metadata details to TempOptab
        CurrTab = readtable(FileDir(i).name); %read in table
        NumSections(i,1) = numel(unique(CurrTab.SectionNum)); %get number of sections in table
    end
    ValDataMetadataTab = TempOpTab; %rename output table
    ValDataMetadataTab.NumSections = NumSections; %add column about number of 5 min sections
end
    

    
    