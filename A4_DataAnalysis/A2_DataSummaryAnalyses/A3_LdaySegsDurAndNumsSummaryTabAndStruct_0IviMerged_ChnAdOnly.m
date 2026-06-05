clear; clc

%Get summary stats (mean, median, etc) for durations of CHNSP, CHNNSP, and AN LENA segment labels in day long data, as well as for number of these segements at teh recording level. 
% Summary stats are computed across all day-long recordings. 
% Also, saves relevant tables with this info as well as plots figures.
% Note that this is for the supplementary info for the Burstiness paper draft, and uses segment labels *after* merging segments of the same type (CHNSP, CHNNSP, or AN) which have 0 
% IVI *and* treats MAN and FAN as the same label categoriy of Adult (Ad or AN).
% Also note that these duration and number summaries exclude recordings at ages other than 3, 6, 9, and 18 mos (but the structure file saved does have other ages from the one infant
% that has recordings at ther ages).

%read in LENA day-long metadata
Basepath = '~/BaseDataPath/';
LdayMetaDataPath = strcat(Basepath,'Data/MetadataFiles/');
cd(LdayMetaDataPath)
opts = detectImportOptions('MergedTSAcousticsMetadata.csv'); %make sure to read in infant code as string, so get options to read the file
opts = setvartype(opts, 'InfantID', 'string'); %set up opts so that infant id is read in as string
LdayMetadataTab = readtable('MergedTSAcousticsMetadata.csv',opts); %read in file with updated options

%read in LENA segemnts (with time series and label info for all LENA segment types)
LdayPath = strcat(Basepath,'Data/LENAData/A8_NoAcoustics_0IviMerged_LENA/');
cd(LdayPath)
LdayFiles = dir('*_NoAcoustics_0IviMerged_LENA.csv');

UniqSegs = {'CHNSP','CHNNSP','AN'}'; %list lf segment labels

if ~isequal(height(LdayMetadataTab),numel(LdayFiles))
    error('Number of files in metadata table and current directory is not the same')
end

%get structure to store duration details
for i = 1:numel(LdayMetadataTab.FileNameRoot) %go through list of file names from metadata table
    CurrTab = readtable(strcat(LdayMetadataTab.FileNameRoot{i},'_NoAcoustics_0IviMerged_LENA.csv')); %read in table
    SegsDur = cell(1,numel(UniqSegs)); %initialise cell array to store durations for each label type
    for k = 1:numel(UniqSegs) %go through labels
        SubTab = CurrTab(contains(CurrTab.speaker,UniqSegs{k}),:); %subset table
        SegsDur{k} = SubTab.xEnd - SubTab.start; %store list fo durations for kth segmet label
    end

    DurStruct(i).TotDurOfSegInRec_Secs = cellfun(@sum,SegsDur); %store total duration of each segment type at the recording level in the structure
    DurStruct(i).TotNumOfSegInRec = cellfun(@numel,SegsDur); %store total numbers of each segment type at the recording level in the structure
    DurStruct(i).DurOfSegments = SegsDur; %SegsDur is cell array where kth element is a vector of durations of all segments of type k in the recording
    DurStruct(i).InfID = LdayMetadataTab.InfantID{i};
    DurStruct(i).InfAgeMos = LdayMetadataTab.InfantAgeMonth(i);
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

%destination to write
Destinationpath = strcat(Basepath,'Data/ResultsTabs/DataDescriptionSummaries/');
cd(Destinationpath)
writetable(SegLvlDurStatsTab,'LdaySegmentLevelDurationSummaryStats_0IviMerged_ChnAdOnly.csv')
writetable(RecLvlSegNumStatsTab,'LdayRecDayLevelSegmentNumsSummaryStats_0IviMerged_ChnAdOnly.csv')
save('LdaySegsDurStruct_0IviMerged_ChnAdOnly.mat','DurStruct')

