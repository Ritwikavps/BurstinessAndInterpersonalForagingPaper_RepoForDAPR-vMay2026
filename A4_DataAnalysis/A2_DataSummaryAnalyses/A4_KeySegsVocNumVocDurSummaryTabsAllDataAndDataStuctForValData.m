clear; clc

%@author info, Sep 2024; This script gets basic summary numbers: 
% total num and duration of vocs for each dataset and breakdown by number of voc types, etc.
% Also get this info for validation data saved in a structure (which is a lil redundant given the table, but still nice to have that info similar to Lday data).

%Get metadata files: LENA day long data
Basepath = '~/BaseDataPath/Data/';
cd(strcat(Basepath,'MetadataFiles/')); %go to required directory
opts = detectImportOptions('MergedTSAcousticsMetadata.csv'); %make sure to read in infant code as string, so get options to read the file
opts = setvartype(opts, 'InfantID', 'string'); %set up opts so that infant id is read in as string
LdayMetadataTab = readtable('MergedTSAcousticsMetadata.csv',opts); %read in file with updated options

%Validation metadata
opts = detectImportOptions('ValDataMergedTSMetaDataTab.csv'); %make sure to read in infant code as string, so get options to read the file
opts = setvartype(opts, 'InfantID', 'string'); %set up opts so that infant id is read in as string
ValMetadataTab = readtable('ValDataMergedTSMetaDataTab.csv',opts); %read in file with updated options

%LENA daylong data info
Lday_Path = strcat(Basepath,'LENAData/A8_NoAcoustics_0IviMerged_LENA/');
Lday_DirStr = '*_LENA.csv'; %the string to use to dir LENA day-long files
cd(Lday_Path); 
LdayDir = dir(Lday_DirStr);

%LENA 5 min files
L5min_Path = strcat(Basepath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A10_NoAcoustics_0IviMerged_L5min/');
L5min_DirStr = '*LENA5min.csv';
cd(L5min_Path);
L5minDir = dir(L5min_DirStr);

%Human-listener labelled data, all adult vocs included.
H5minAllAdPath = strcat(Basepath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A9_NoAcoustics_0IviMerged_Hum/');
H5minAllAd_DirStr = '*0IviMerged_Hum.csv';
cd(H5minAllAdPath);
H5minAllDir = dir(H5minAllAd_DirStr);

DatasetType = {'Lday';'L5min';'H5min-AllAd'}; %list of the data sets 
DataDir = {LdayDir,L5minDir,H5minAllDir};
AgeMonth = [3 6 9 18]'; %infant age
DestinationPath = strcat(Basepath,'ResultsTabs/DataDescriptionSummaries/');

%Human-listener labelled data, only infant-directed adult vocs as adult. We only need the summary stats for this cuz the detailed tables (saved as excel sheets)
% are broken down by annotation as well, so it is simply a matter of logical indexing to get the TAd details.
H5minTAdPath = strcat(Basepath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A11_NoAcoustics_0IviMerged_Hum_ChildDirANOnly/');
H5minTAd_DirStr = '*ChildDirANOnly_Hum.csv';
cd(H5minTAdPath);
H5minTAdDir = dir(H5minTAd_DirStr);
                                                
%-----------------------------------------------------------------------------------------------------------
%I) Get tables with summary stats for duration of segments and number fo segments in a file by segment type as well as structures with list of durations of all segments by type
%-----------------------------------------------------------------------------------------------------------
[SegLvlDurStatsTab_L5,RecLvlSegNumStatsTab_L5,DurStruct_L5] = GetDurStructForValData(ValMetadataTab,L5minDir,...
                                                            '_NoAcoustics_0IviMerged_LENA5min.csv',DestinationPath,'L5min');
[SegLvlDurStatsTab_H5AllAd,RecLvlSegNumStatsTab_H5AllAd,DurStruct_H5AllAd] = GetDurStructForValData(ValMetadataTab,H5minAllDir,...
                                                                                    '_NoAcoustics_0IviMerged_Hum.csv',DestinationPath,'H5min-AllAd');
[SegLvlDurStatsTab_H5TAd,RecLvlSegNumStatsTab_H5TAd,DurStruct_H5TAd] = GetDurStructForValData(ValMetadataTab,H5minTAdDir,...
                                                                                    '_NoAcoustics_0IviMerged_ChildDirANOnly_Hum.csv',DestinationPath,'H5min-TAd');

%-----------------------------------------------------------------------------------------------------------
%II) Total number of vocs in each file + breakdown by type and age + mean number of total vocs and each type voc (overall and by age)
%-----------------------------------------------------------------------------------------------------------
[OpTabNums_FileLvl, ByAgeAndVocTypeNumsTab, ByVocTypeNumsTab, ByAgeNumsTab,...  %see relevant user-defined function for details.
              OpTabDur_FileLvl, ByAgeAndVocTypeDurTab, ByVocTypeDurTab, ByAgeDurTab, TotNums, TotDur] = GetDataSummaryDetails(DatasetType,DataDir,LdayMetadataTab,AgeMonth);

%Saving all files
cd(DestinationPath);
for i = 1:numel(DatasetType) %write documents for each dataset type
    DurFname = strcat('TotVocDurSummaries_0IviMerged_ChnAdOnly_',DatasetType{i},'.xlsx'); %file name for duration numbers
    NumsFname = strcat('TotVocNumsSummaries_0IviMerged_ChnAdOnly_',DatasetType{i},'.xlsx'); %file name for total voc numbers

    writetable(TotDur{i},DurFname,'Sheet','TotDur','Range','A1')
    writetable(OpTabDur_FileLvl{i},DurFname,'Sheet','FileLvlTotDurOfSegs','Range','A1')
    writetable(ByAgeAndVocTypeDurTab{i},DurFname,'Sheet','TotDurByAgeAndVocType','Range','A1')
    writetable(ByVocTypeDurTab{i},DurFname,'Sheet','TotDurByVocType','Range','A1')
    writetable(ByAgeDurTab{i},DurFname,'Sheet','TotDurByAge','Range','A1')

    writetable(TotNums{i},NumsFname,'Sheet','TotNum','Range','A1')
    writetable(OpTabNums_FileLvl{i},NumsFname,'Sheet','FileLvlTotNumOfSegs','Range','A1')
    writetable(ByAgeAndVocTypeNumsTab{i},NumsFname,'Sheet','TotNumByAgeAndVocType','Range','A1')
    writetable(ByVocTypeNumsTab{i},NumsFname,'Sheet','TotNumByVocType','Range','A1')
    writetable(ByAgeNumsTab{i},NumsFname,'Sheet','TotNumByAge','Range','A1')
end

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%Functions used:
%-----------------------------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------------------------
%I) Get number of infants who have recordings for every age for day-long data and validation data, as well.
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

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%II) Get structure with list of durations of CHNSP, CHNNSP, and AN segments, total number of each segemnts, and total number of each segments in each validation file.
% In addition, also computes mean, median, std dev., min anx max of duration of each segment type, and number of each segment type in a validation file.
%----------------------------------------------------------------------------------------------------------
% Inputs: - MetadataTab: relevant metadata file.
%         - FilesDir: list of files for the relevant dataset.
%         - FnameStr: The string in the file name common to all desired files to use to dir
%         - DestinationPath: path to save output files
%         - DataTypePrefix: String specifying type of dataset (to use as prefix for writing files)
function [SegLvlDurStatsTab,RecLvlSegNumStatsTab,DurStruct] = GetDurStructForValData(MetadataTab,FilesDir,FnameStr,DestinationPath,DataTypePrefix)

    UniqSegs = {'CHNSP','CHNNSP','AN'}'; %list of segment labels
    
    if ~isequal(height(MetadataTab),numel(FilesDir))
        error('Number of files in metadata table and current directory is not the same')
    end
    
    %get structure to store duration details
    for i = 1:numel(MetadataTab.FileNameRoot) %go through list of file names from metadata table
        CurrTab = readtable(strcat(MetadataTab.FileNameRoot{i},FnameStr)); %read in table; Fnamestr is the suffix for the file name to grab it.
        SegsDur = cell(1,numel(UniqSegs)); %initialise cell array to store durations for each label type
        Num5minSecs = numel(unique(CurrTab.SectionNum));
        for k = 1:numel(UniqSegs) %go through labels
            SubTab = CurrTab(contains(CurrTab.speaker,UniqSegs{k}),:); %subset table
            SegsDur{k} = SubTab.xEnd - SubTab.start; %store list fo durations for kth segmet label
        end
    
        DurStruct(i).TotDurOfSegInRec_Secs = cellfun(@sum,SegsDur); %store total duration of each segment type at the recording level in the structure
        DurStruct(i).TotNumOfSegInRec = cellfun(@numel,SegsDur); %store total numbers of each segment type at the recording level in the structure
        DurStruct(i).DurOfSegments = SegsDur; %SegsDur is cell array where kth element is a vector of durations of all segments of type k in the recording
        DurStruct(i).InfID = MetadataTab.InfantID{i};
        DurStruct(i).InfAgeMos = MetadataTab.InfantAgeMonth(i);
        if strcmp(MetadataTab.FileNameRoot{i},'0014_000301')
            DurStruct(i).TotFileDur_Secs = (Num5minSecs-1)*5*60 + 3*60; %this file has one section that is 3 minutes long
        else
            DurStruct(i).TotFileDur_Secs = Num5minSecs*5*60; %get total duration of the validation file in seconds. 
        end
    end
    
    DurStruct(1).SegsList = UniqSegs; %store list of segments
    
    %get duration mean, median, max, and min for all ages together, for all segment labels.
    for i = 1:numel(UniqSegs)
        TempDurVec = [];
        for j = 1:numel(DurStruct)
            if ismember(DurStruct(j).InfAgeMos,[3 6 9 18]) %only proceed if age is 3, 6, 9, or 18 mos. If not, do not add to summary duration and number stats computation
                TempDurVec = [TempDurVec; DurStruct(j).DurOfSegments{i}];
            end
        end
        MeanDurSegs_SegLvl(i,1) = mean(TempDurVec,'omitnan');
        StdDurSegs_SegLvl(i,1) = std(TempDurVec,'omitnan');
        MinDurSegs_SegLvl(i,1) = min(TempDurVec);
        MaxDurSegs_SegLvl(i,1) = max(TempDurVec);
        MedianDurSegs_SegLvl(i,1) = median(TempDurVec);
        TotDurSegs_DataLvl(i,1) = sum(TempDurVec);
    end
    
    %Get mean number of different segs at the rec level.
    for i = 1:numel(UniqSegs) %go through list of un ique segemnt labels
        TempNumVec = [];
        for j = 1:numel(DurStruct) %go through struct
            if ismember(DurStruct(j).InfAgeMos,[3 6 9 18]) %only proceed if age is 3, 6, 9, or 18 mos. If not, do not add to summary duration and number stats computation
                TempNumVec = [TempNumVec; DurStruct(j).TotNumOfSegInRec(i)]; %pull out tot number of segment label i in each structure element cell array
            end
        end
        MeanNumSegs_RecLvl(i,1) = mean(TempNumVec,'omitnan'); %get stat numbers
        StdNumSegs_RecLvl(i,1) = std(TempNumVec,'omitnan');
        MinNumSegs_RecLvl(i,1) = min(TempNumVec);
        MaxNumSegs_RecLvl(i,1) = max(TempNumVec);
        MedianNumSegs_RecLvl(i,1) = median(TempNumVec);
        TotNumSegs_DataLvl(i,1) = sum(TempNumVec);
    end
    
    %table with decriptive stats for duration: mean, median etc duration of each segemnt type (calculated across the entire data set) + total duration of each segementlabel type at the 
    % dataset level.
    SegLvlDurStatsTab = table(UniqSegs,MeanDurSegs_SegLvl,StdDurSegs_SegLvl,MedianDurSegs_SegLvl,MaxDurSegs_SegLvl,MinDurSegs_SegLvl,TotDurSegs_DataLvl);
    SegLvlDurStatsTab.Properties.VariableNames = {'SegmentLabels','MeanDur_s','StdDevDur_s','MedianDur_s','MaxDur_s','MinDur_s','TotDur_s_DataLvl'};
    
    %table with decriptive stats for number of segment labels: mean, median etc number of each segemnt type at the recording level (calculated across the entire data set). That is,
    % we compute the total number of each segemnt type in each recording and then get the mean, median etc of the number of this distribution + total duration of each segementlabel 
    % type at the dataset level.
    RecLvlSegNumStatsTab = table(UniqSegs,MeanNumSegs_RecLvl,StdNumSegs_RecLvl,MedianNumSegs_RecLvl,MaxNumSegs_RecLvl,MinNumSegs_RecLvl,TotNumSegs_DataLvl);
    RecLvlSegNumStatsTab.Properties.VariableNames = {'SegmentLabels','MeanNum','StdDevNum','MedianNum','MaxNum','MinNum','TotNum_DataLvl'};

    %save files
    cd(DestinationPath)
    writetable(SegLvlDurStatsTab,strcat(DataTypePrefix,'SegmentLevelDurationSummaryStats_0IviMerged_ChnAdOnly.csv'))
    writetable(RecLvlSegNumStatsTab,strcat(DataTypePrefix,'RecDayLevelSegmentNumsSummaryStats_0IviMerged_ChnAdOnly.csv'))
    save(strcat(DataTypePrefix,'SegsDurStruct_0IviMerged_ChnAdOnly.mat'),'DurStruct')
end