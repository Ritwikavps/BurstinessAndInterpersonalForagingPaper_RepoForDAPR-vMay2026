clear; clc

%%@author info, Apr 2022
%Code to test if there are tier names that are vairations of the standard names.
%You can run this again on the .csv files parsed from the cleaned-up .eaf files to make sure that everything is in order
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%get path where csv files parsed from eaf files are; CHANGE PATH ACCORDINGLY
BasePath = '~/BaseDataPath/';%This is the base path to the google drive folder that may undergo change
CsvPath = strcat(BasePath,'Data/HUMLabelData/A1_HUMLabelData_CleanupPipeline/A2_ParsedEafFilesFromR_PreCleanUp/');
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------

cd(CsvPath) %go to path
CsvDir = dir('*.csv'); %Get .csv files

%This is the bit to figure out unique tier names across the entire dataset;
UniqueTierNames = {}; %set up empty cell arrya to store the set of unique tier names for each .csv file
for i = 1:numel(CsvDir)
    CsvTab = readtable(CsvDir(i).name,'Delimiter',','); %read csv file

    UniqueTiers_Temp = unique(CsvTab.TierTypeVec); %get unique tier names
    UniqueTierNames = [UniqueTierNames; UniqueTiers_Temp]; %add the set to master tier names cell array
end

unique(UniqueTierNames)