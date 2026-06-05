clear; clc

%%@author info, August 2022; updated Dec 2023

%This script does the following:
    % -adds back annotation tags (T, U, N for adult vocs; R, X, C, L for infant vocs) to the csv files with time series and acoustics info
    % -recasts speaker labels as CHN and CHNNSP
    % -removed vocs (or sub-vocs) that are tagged as OLP, and retain only the sub-vocs are non-overlapping, when part of a voc overlaps with part or all of other voc(s).

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------  
%CHANGE PATHS AND STRINGS INSIDE FUNCTION CALL AS NECESSARY.
BasePath = '~/BaseDataPath/Data/HUMLabelData/A2_HUMLabelData_PostCleanUp';

LabelswVocIndPath = strcat(BasePath,'/A3_HlabelsOlpProcessed/');
TSpath = strcat(BasePath,'/A4_HlabelTS_OlpProcessed/');
VocStitchPath = strcat(BasePath,'/A2_HlabelCsvFiles/'); %this is the path with the unprocessed .csv files, so we can check all vocs have
% OLP processed and reconstituted correctly.
destinationpath = strcat(BasePath,'/A5_HlabelTS_OlpRemoved/');

%go to directory that has labels w/ voc index and annotation tags, and dir
cd(LabelswVocIndPath); LabelswVocIndFiles = dir('*_OlpProc.csv');

%go to directory with time series and dir
cd(TSpath); TSfiles = dir('*_TSOlpProc.csv');
%---------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

%first check that the number of TSfiles and the number of label files are the same, and then, that all TSfiles have a corresponding Label file and vice-vers
if numel(TSfiles) ~= numel(LabelswVocIndFiles)
    error('Different number of files in TS directory (A4_HlabelTS_OlpProcessed) and Label files directory (A3_HlabelsOlpProcessed)')
end

for i = 1:numel(TSfiles)
    TSFnrootVec{i,1} = erase(TSfiles(i).name,'_TSOlpProc.csv'); 
end

for i = 1:numel(LabelswVocIndFiles)
    LabelsFnrootVec{i,1} = erase(LabelswVocIndFiles(i).name,'_OlpProc.csv'); 
end

if ~isempty(setdiff(TSFnrootVec,LabelsFnrootVec))
    setdiff(TSFnrootVec,LabelsFnrootVec)
    error('There are TS files (A4_HlabelTS_OlpProcessed) that are not in the list of Label files (A3_HlabelsOlpProcessed); see above')
end

if ~isempty(setdiff(LabelsFnrootVec,TSFnrootVec))
    setdiff(LabelsFnrootVec,TSFnrootVec)
    error('There are Label files (A3_HlabelsOlpProcessed) that are not in the list of TS files (A4_HlabelTS_OlpProcessed); see above')
end

%proceed once the above checks are passed!!

for i = 1:numel(TSFnrootVec) %go through TSfiles, match to correpsonding label file, add annotation tags
 
    %---------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
    LabelsFname = strcat(LabelswVocIndPath,TSFnrootVec{i},'_OlpProc.csv'); %get labels and TS filenames; CHANGE STRINGS INSIDE FUNCTION CALL AS NECESSARY.
    TSFname = strcat(TSpath,TSFnrootVec{i},'_TSOlpProc.csv');
    %---------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

    if ~isfile(LabelsFname) %error checks (redundant but better safe than sorry :) Also, this way, we are sure that the filenames match
        disp(strcat('Labels file corresponding to fnroot ',TSFnrootVec{i},' does not exist.'))
    end

    if ~isfile(TSFname)
        disp(strcat('TS file corresponding to fnroot ',TSFnrootVec{i},' does not exist.'))
    end

    TStab = readtable(TSFname,'Delimiter',','); %read in tables
    LabelsTab = readtable(LabelsFname,'Delimiter',',');

    %check that TS and Labels tables have the same number of rows
    if size(TStab,1) ~= size(LabelsTab,1)
        disp(strcat('Number of rows for TS and Labels files for ',TSFnrootVec{i},' do not match'))
    end

    %check if start and end columns are equal for TS and Labels tables
    if (isequal(TStab.start,LabelsTab.StartTimeVal/1000)) && (isequal(TStab.xEnd,LabelsTab.EndTimeVal/1000))

        %check to make sure that CHN vocs arent tagged T, U, or N, and vice-versa for adult vocs
        CHN_TagCheck = contains(LabelsTab.Annotation(contains(TStab.speaker,'CHN')),{'T','U','N'}); %returns logical 1 or 0 (yes or no)
        %for all annotation tags corresponding to CHN speaker that contains annotation tags that should be for AN
        AN_TagCheck = contains(LabelsTab.Annotation(contains(TStab.speaker,'AN')),{'R','X','L','C'}); %sim for AN tags
        OLP_TagCheck = isequal(LabelsTab.Annotation(contains(LabelsTab.Annotation,'OLP')),TStab.speaker(contains(TStab.speaker,'OLP'))); %checks that the vectors of all OLP tags
        %are the same for TS and Labels tables

        if ((sum([CHN_TagCheck; AN_TagCheck])) == 0) && (OLP_TagCheck == 1) %if both of these checkes sum to 0 AND if the OLP tag check checks out,
            % add annotation and VocIndex column to table
            TStab.Annotation = LabelsTab.Annotation;
            TStab.VocIndex = LabelsTab.VocIndex;
        else
            disp(strcat('Tag checks for CHN, AN and/or OLP speaker labels for ',TSFnrootVec{i},' return error.'))
        end
    else
        disp(strcat('Vectors of start and end times for TS and Labels files for ',TSFnrootVec{i},' do not match'))
    end

    %Now, let's remove all sub-vocs tagged OLP. First, we will match each voc to its voc index. Then, we will compare the vocs with the same voc index to the vocalisation with the same
    % voc index in the original (pre-overlap processing) table with labels. Then, we will see if the sub-vocs span the entire original (unchopped) vocalisation. Once this check is passed,
    % we remove all vocs tagged OLP.

    %---------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
    %CHANGE STRINGS INSIDE FUNCTION CALL AS NECESSARY.
    %Check to make sure that the start and end times of unprocessed vocs are the same as post-OLP processing and stitcthing back together.
    StitchCheckTab = readtable(strcat(VocStitchPath,TSFnrootVec{i},'.csv'),'Delimiter',','); %read initial csv table (parsed from eaf) 
    %---------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
    StitchCheckTab = StitchCheckTab(contains(StitchCheckTab.TierTypeVec,{'Infant Voc Type','Adult Utterance Direction'}),:); %get Inf Voc and Adult utt dir tiers ONLY
    StitchCheckTab = sortrows(StitchCheckTab,'StartTimeVal'); %sort table by start time

    AnAnnots = unique(StitchCheckTab.Annotation(contains(StitchCheckTab.TierTypeVec,'Adult'))); %get sets of infant and adult annotations
    ChnAnnots =  unique(StitchCheckTab.Annotation(contains(StitchCheckTab.TierTypeVec,'Infant'))); 

    %get unique Voc Indices
    U_VocInd = unique(TStab.VocIndex);

    for j = 1:numel(U_VocInd) %go through list of unique voc indices
        SubTab = TStab(TStab.VocIndex == U_VocInd(j),:); %get sub-table for each voc index

        u_SubTabSpkr_noOLP = setdiff(unique(SubTab.speaker),'OLP'); %get all unique speakers in the sub-table
        if numel(u_SubTabSpkr_noOLP) > 1 %check if other than potential OLP labels, there is only one unique speaker
            error('More than one unique speaker label (that is not overlap) in this sub-table')
        end

        if ~isempty(u_SubTabSpkr_noOLP) %proceed only if there are speaker labels other than OLP
            % Find corresponding voc with the same start time in the non-olp processed data table
            SubTabForCheck = StitchCheckTab(StitchCheckTab.StartTimeVal/1000 == min(SubTab.start),:);
            if strcmp(u_SubTabSpkr_noOLP{1},'AN') %get the correct speaker type for the subsetted tab for checking (in case there are overlaps)
                SubTabForCheck = SubTabForCheck(contains(SubTabForCheck.Annotation,AnAnnots),:);
            elseif strcmp(u_SubTabSpkr_noOLP{1},'CHN')
                SubTabForCheck = SubTabForCheck(contains(SubTabForCheck.Annotation,ChnAnnots),:);
            else
                error('Unrecognised speaker label in processed data')
            end

            %Check that after filtering for the correct vocalisation type (CHN or AN) there is only one vocalisation (which is the non-overlap processed
            % vocalisation with the given start time and corresponding to the current vocalisation index) in SubTabForCheck.
            if height(SubTabForCheck) ~= 1 
                error('There should only be one vocalisation in SubTabForCheck')
            end 

            %check that start and end times for the set of chopped up vocs span the entire unchopped voc.
            if (min(SubTab.start) ~= SubTabForCheck.StartTimeVal/1000) || (max(SubTab.xEnd) ~= SubTabForCheck.EndTimeVal/1000)
                error('Chopped up vocs do not span the entire unchopped up voc')
            end
        end
    end

    %Make new table and remove OLPs
    TabToSave = TStab;
    TabToSave(contains(TabToSave.speaker,'OLP'),:) = []; 
                                    
    %remove VocIndex
    TabToSave = removevars(TabToSave,{'VocIndex'});
    TabToSave.speaker(contains(TabToSave.Annotation,{'L','R'}) & contains(TabToSave.speaker,'CHN')) = {'CHNNSP'}; %recast CHN speaker labels as CHNSP and CHNNSP
    TabToSave.speaker(contains(TabToSave.Annotation,{'X','C'}) & contains(TabToSave.speaker,'CHN')) = {'CHNSP'};
    if ~isempty(TabToSave.Annotation(contains(TabToSave.Annotation,'OLP'))) || ~isempty(TabToSave.speaker(contains(TabToSave.speaker,'OLP')))
        error('Not all OLP labels removed')
    end
    
    writetable(TabToSave,strcat(destinationpath,TSFnrootVec{i},'_TS_OlpRemoved.csv')) %save the new table
end
