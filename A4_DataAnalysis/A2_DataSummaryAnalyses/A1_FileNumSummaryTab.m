clear; clc

%@author info, Sep 2024; This script gets basic summary numbers: number of total recordings for each dataset (LENA day long, LENA/hum labelled 5 min)
% and number of infants that have 3 annotated 5-min sections.

%Get metadata file
cd('~/BaseDataPath/Data/MetadataFiles/'); %go to required directory
opts = detectImportOptions('MergedTSAcousticsMetadata.csv'); %make sure to read in infant code as string, so get options to read the file
opts = setvartype(opts, 'InfantID', 'string'); %set up opts so that infant id is read in as string
MetadataTab = readtable('MergedTSAcousticsMetadata.csv',opts); %read in file with updated options

%Get metadata files: validation data
cd('~/BaseDataPath/Data/MetadataFiles')
opts = detectImportOptions('ValDataMergedTSMetaDataTab.csv'); %make sure to read in infant code as string, so get options to read the file
opts = setvartype(opts, 'InfantID', 'string'); %set up opts so that infant id is read in as string
ValdataMetadataTab = readtable('ValDataMergedTSMetaDataTab.csv',opts); %read in file with updated options

MetadataCell = {MetadataTab,ValdataMetadataTab}; %put into cell array to loop over
DatasetType = {'Lday';'ValData'}; %list of the data sets 
AgeMonth = [3 6 9 18]'; %infant age

%-----------------------------------------------------------------------------------------------------------
%I) Get the total number of recordings for each dataset and age breakdown
%-----------------------------------------------------------------------------------------------------------
for i = 1:numel(DatasetType)
    Curr_NumFilesByAge{i} = GetNumFilesByAge(AgeMonth,MetadataCell{i}); %Get number of files for each age (3, 6, 9, and 18 mos) for day-long LENA and validation data
    % (this will be a col vector, so the eventual table looks like this: 
    %           AgeMonths |  Lday     | ValData | 
    %                     |    3      |   xx    | 
    %                     |    6      |   xx    | 
    %                     |    9      |   xx    | 
    TotNumFileswAllAges(i) = numel(MetadataCell{i}.FileNameRoot); %get total number of LENA day long files
    TotNumFiles_OnlyReqAges(i) = sum(Curr_NumFilesByAge{i}); %get number of files for only the required number of ages for LENA day long data (cuz we have a few files taht are from other 
    % ages in the day-long dataset that we do not use, but these numbers are nice to have)
end

NumFilesAtExcludedAges = TotNumFileswAllAges-TotNumFiles_OnlyReqAges; %get number of excluded files for each dataset type; (should be 0 for validation data) by subtracting total 
% file numbers based on sum from ages 3, 6, 9, and 18 mo, from total number of files in directory.

FileNumTab = table(AgeMonth,Curr_NumFilesByAge{1},Curr_NumFilesByAge{2}); %put number of files info into a table1
FileNumTab(end+1,:) = sum(FileNumTab,1); %get the sum fo each column (to get total number of files for each dataset type); note that this sum only sums files at ages 3, 6, 9, and 18 mo
FileNumTab(end+1,2:3) = array2table(NumFilesAtExcludedAges); %add number of excluded files row
for i = 1:numel(DatasetType)
    FileNumTab.Properties.VariableNames{i+1} = strcat('NumFiles_',DatasetType{i}); %rename second and third columns 
end 
FileNumTab.AgeMonth = {'3';'6';'9';'18';'Totals';'NumFilesAtExcludedAges'}; %re-assign first column (because the second last row is now the sum of each column, and last row has number
% of excluded files ie, files not at 3, 6, 9, or 18 mo (should be 0 for validation data)

if FileNumTab.NumFiles_ValData(end) ~= 0
    error('Number of excluded files (ie. files not at age 3, 6, 9, or 18 mo) should be 0 for validation data')
end

writetable(FileNumTab,'NumFilesSummary.csv') %write table with number of files/recordings to csv file

%-----------------------------------------------------------------------------------------------------------
%II) Get number of infants who have recordings for every age for day-long data and validation data, as well.
%-----------------------------------------------------------------------------------------------------------
uID_Lday = unique(MetadataTab.InfantID); %get list of unique ids 
uID_ValData =  unique(ValdataMetadataTab.InfantID);

AllAgesCtr_Lday = GetNumInfantsWAllAges(uID_Lday,MetadataTab.InfantID,MetadataTab.InfantAgeMonth); %get number of infants with all ages for day-long data and validation data
AllAgesCtr_ValData = GetNumInfantsWAllAges(uID_ValData,ValdataMetadataTab.InfantID,ValdataMetadataTab.InfantAgeMonth);

NumFilesWo3Sections = numel(ValdataMetadataTab.NumSections(ValdataMetadataTab.NumSections ~= 3)); %get number of validation data files where number of sections is not equal to 3

sprintf('%i infants are represented in the LENA day-long dataset, while %i infants are represented in the validation dataset',...
                                                                numel(unique(MetadataTab.InfantID)),numel(unique(ValdataMetadataTab.InfantID)))
sprintf('%i infants have recordings at all ages for LENA day-long data, %i infants have files at all ages for validation data)',AllAgesCtr_Lday,AllAgesCtr_ValData) 
sprintf('%i files in the validation dataset do not have 3 annotated sections',NumFilesWo3Sections) %'0225_000301' has 4 sections, one from the 'a' subrecording, 3 from 'b' subrec



%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%Functions used:
%-----------------------------------------------------------------------------------------------------------
%This function gets the by-age breakdown of total number of files.
%Inputs: - AgeMonth: vector of the required ages (in months)
%        - TabwRelevantMetadata: table with metadata for files we have (because the validation data does not have all the files the daylong data has)
% 
% Output: - NumFilesByAge: : vector with by-age breakdown of files (ie., number of files per age).
function NumFilesByAge = GetNumFilesByAge(AgeMonth,TabwRelevantMetadata)
    for i = 1:numel(AgeMonth) %go through ages
        NumFilesByAge(i,1) = numel(TabwRelevantMetadata.InfantAgeMonth(TabwRelevantMetadata.InfantAgeMonth == AgeMonth(i)));  %get number of files for each age by picking
        %out the files that are only that age and getting the length of the subsetted age vector
    end
end

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%III) Get number of infants who have recordings for every age for day-long data and validation data, as well.
%----------------------------------------------------------------------------------------------------------
% Inputs: - uID: list of unique infant IDs
%         - IDvec: list of infant IDs for the dataset
%         - Agevec: list of infant ages for the dataset
% 
% Output: AllAgesCtr: counter variable that is the number of infants who have files at all [3 6 9 18] mos.
function AllAgesCtr = GetNumInfantsWAllAges(uID,IDvec,AgeVec)
    AllAgesCtr = 0; %Initialise counter
    for i = 1:numel(uID) %go through list of unique ideas
        AgesForCurrID = AgeVec(ismember(IDvec,uID{i})); %get list of ages for the current ID
        %Check that there are at least 4 ages in this list, AND that the list of ages contains [3 6 9 18] mos.
        if (numel(AgesForCurrID) >= 4) && (sum(ismember(AgesForCurrID,[3 6 9 18])) == 4) 
            AllAgesCtr = AllAgesCtr + 1; %increment counter
        end
    end
end