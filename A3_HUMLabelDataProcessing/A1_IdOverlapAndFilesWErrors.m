clearvars; clc

%%@author info; July 2022

%Updated June 2023, post the clean-up effort by auth1 and co-auth in May 2023
% Prior to this clean-up effort, there were files which contained errors (see relevnt directory; A2_HUMLabelDataCleanUp), so it was necessary to exclude those files, 
% and so, this script contained some code to do that. Post- the May 2023 clean-up effort, this is no longer necessary, and I have removed those portions of code, and 
% am leaving this note here to sort of point to the fact that extensive data cleanup has been performed, and also, in case the need to add similar portions of code 
% ever arises.
% 
% This script also returns summary numbers for the overlap processing process and saves the relevant table in metadatafiles. 

% As of now, this script checks if there are overlapping vocalisations, splits overlapping vocs into non-overlapping sub-vocs where possible, and
% otherwise tags those vocs as overlapping so they are not used in acoustic analysis

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%set BasePath and working directory; CHNAGE PATH AS NECESSARY
BasePath = '~/BaseDataPath/Data/HUMLabelData/A2_HUMLabelData_PostCleanUp/';
WorkingDir = strcat(BasePath,'A2_HlabelCsvFiles/');
cd(WorkingDir)
FilesToProc = dir('*.csv'); %Now read in human listner labelled data and id and process overlaps
DestinationPath = strcat(BasePath,'A3_HlabelsOlpProcessed/'); %File path to save files post processing for overlaps
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------

%The basic idea is to pick out all CHN and AN vocs, sort them by start time into a single table, index each voc with a sequential index (1, 2, 3....), identify
% and flag overlapping vocs (see below; utilises user-defined function), and chop up all overlapping vocs into overlapping and non-overlapping sub-vocs while
% also storing the info about the voc index of the original un-chopped up vocalisation. So, if Voc 3 is chopped up into 3 sub-vocs, they will all have the voc
% index 3. Note that this chopping up of overlapping vocs is done recursively (see below; utilises user-defined function). We will later use this voc index info 
% to stitch back vocs together after acoustic processing.

%initialise various overlap counters. Eg. FullOlpCtr (vector with one entry each for CHNSP, CHNNSP, and AN, in that order) counts number of instances when an utterance is 
% overlapped fully (straddled fully) by another utterance type such that the focal utterance is fully processed out after olp processing. For the first element in FullOlpCtr,
% this number corresponds to the number of CHNSP utterances that are fully overlapped by an adult utterance (CHNSP cannot be fully overlapped by a CHNSP type 
% because they are two distinct utterance types from the same vocaliser). The second and third elements index full overlaps for CHNNSP and AN vocs, similarly. 
% PartialOlpCtr counts the number of times there is a partial overlap such that some portion of the utterance in question remains after overlap processing. The PartialOlpCtr
% vector is also in the order of number of partial overlaps for CHNSP, CHNNSP, and AN.
% DurSums_PreOlp and NumSums_PreOlp tracks the total duration and number of the vocalisation type in question prior to overlap processing, in the order of CHNSP, CHNNSP, and AN.
% Finally, DurSums_PostOlp and NumSums_PostOlp tracks the total duration and number of the vocalisation type in question after to overlap processing, in the order of CHNSP, 
% CHNNSP, and AN.
FullOlpCtr = [0 0 0]; PartialOlpCtr = [0 0 0]; 
DurSums_PreOlp = [0 0 0]; NumSums_PreOlp = [0 0 0];
DurSums_PostOlp = [0 0 0]; NumSums_PostOlp = [0 0 0];

for i = 1:numel(FilesToProc) %go through the listof files to work on

    i

    HlabelTab = readtable(FilesToProc(i).name,'Delimiter',','); %read table
    %----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    FnameToSave = strcat(DestinationPath,regexprep(FilesToProc(i).name,'.csv',''),'_OlpProc.csv'); %filename (and path) to save .csv files after 
    %processing overlaps; %CHANGE STRINGS INSIDE FUNCTION CALL TO MATCH ANY CHANGES IN FILENAMING CONVENTIONS
    %----------------------------------------------------------------------------------------------------------------------------------------------------------------------

    %Get Inf Voc type and Adult Utt dir portion of the table to generate relevant voc data table
    NewSubTable = HlabelTab(contains(HlabelTab.TierTypeVec,{'Infant Voc Type','Adult Utterance'},'IgnoreCase',true),:);
    
    StartTimeSortTable = sortrows(NewSubTable,'StartTimeVal'); %sort by start time 
    OlpFlag = DetectOverlap(StartTimeSortTable); %get overlap flag vector (see function DetectOverlap for details)
    VocIndex = (1:numel(OlpFlag))'; %get vector of voc indices. We'll use this to stitch vocs back together
    StartTimeSortTable.VocIndex = VocIndex; %Add voc index info to table
    PreOlpProcFile = StartTimeSortTable; %make copy to estimate number of vocs that are fully and partially overlapped
    %--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    %%DEBUGGING BIT: 
    % ss = StartTimeSortTable(OverLapFlag == 1,:); ss(:,[7,10,11]); Ctr = 0; This basically picks out the annotation,
    %%start and end times for vocs flagges as overlapping, so we can do a visual check
    %--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    while sum(OlpFlag) > 0  %as long as there are overlap flags
        %--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        %%DEBUGGING BIT: 
        % display('----------------------------'); Ctr = Ctr + 1; size(StartTimeSortTable)
        % ss = StartTimeSortTable(OverLapFlag == 1,:); ss(:,[7,10,11]);
        %--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        [TableWithOverlapProcessed] = GetNonOverlapVocs(StartTimeSortTable,OlpFlag); %get table with overlapping vocs flagged and/or chopped into overlapping and 
        % non-overlapping sub-vocs. Note that this needs to be donoe recursively till we get to a table with no overlaps (see function for details)
        OlpFlag = DetectOverlap(TableWithOverlapProcessed); %detect overlap flag for new table
        
        for j = 1:numel(OlpFlag) %if a voc in the new table is tagged as a full overlap, ignore its overlap flag = 1
            if strcmpi(TableWithOverlapProcessed.Annotation{j},'OLP')
                OlpFlag(j) = 0;
            end
        end

        %--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        %DEBUGGING BIT:setdiff(StartTimeSortTable,TableWithOverlapProcessed); size(TableWithOverlapProcessed)
        %--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        StartTimeSortTable = TableWithOverlapProcessed; %recast new table with the old table name so the while loop can continue
    end

    %Once we get a stable table, resort
    FinalTab = sortrows(StartTimeSortTable,'StartTimeVal');
    writetable(FinalTab,FnameToSave);

    %Get summary numbers for overlap processing. Keep in mind that all outputs below from functions are running sums where the total number of overlaps, durations etc get added
    % to the counter for each file (indexed by i). 
    [FullOlpCtr, PartialOlpCtr] = GetNumOfFullOlpAndPartialOlp(FinalTab,PreOlpProcFile,FullOlpCtr, PartialOlpCtr);
    %total duration and numbers of CHNSP, CHNNSP, and AN (in that order) for files pre olp-process
    [DurSums_PreOlp,NumSums_PreOlp] = GetDursAndNums(PreOlpProcFile,DurSums_PreOlp,NumSums_PreOlp); 
    %total duration and numbers of CHNSP, CHNNSP, and AN (in that order) for files post olp-process
    [DurSums_PostOlp,NumSums_PostOlp] = GetDursAndNums(FinalTab,DurSums_PostOlp,NumSums_PostOlp);
end

OlpSummaryArray = [FullOlpCtr; 
                   PartialOlpCtr; 
                   NumSums_PreOlp;
                   NumSums_PostOlp;
                   DurSums_PreOlp;
                   DurSums_PostOlp;
                   DurSums_PreOlp-DurSums_PostOlp]; %make array
OlpSummaryTab = array2table(OlpSummaryArray); %convert to table
OlpSummaryTab.Properties.VariableNames = {'CHNSP','CHNNSP','AN'}; %add col names
%get table with row names
RowNamesTab = array2table({'Num. Full Olp','Num. Partial Olps','Tot. Num. Vocs Pre-Olp Process','Tot. Num. Vocs Post-Olp Process',...
                            'Tot. Duration of Vocs Pre-Olp Process','Tot. Duration of Vocs Pre-Olp Process','Diff in Duration of Vocs Pre and Post-Olp Process'}');
OlpSummaryTab = [RowNamesTab OlpSummaryTab]; %add to table
cd('~/BaseDataPath/Data/MetadataFiles')
writetable(OlpSummaryTab,'OlpSummaryNumbers.csv')





%-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%Functions used
%-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%This function gets the total durations and numbers of CHNSP, CHNNSP, and AN (in that order) vocs for a given file (CurrTab). This also required the initial input DurSums and 
% NumSums which are vectors with a running sum of total duration and numbers of CHNSP, CHNNSP, and AN upto the current file.
% The outputs, DurSum and NumSums are row vectors with the first element corresponding to CHNSP, the second element to CHNNSP, and the third to AN, cumulatively, upto and 
% including details for CurrTab.
%--------------------------------------------------------
function [DurSums,NumSums] = GetDursAndNums(CurrTab,DurSums,NumSums)

    Annots = {{'C','X'},{'R','L'},{'T','U','N'}}; %Get sets of annotations
    CurrTab = CurrTab(contains(CurrTab.TierTypeVec,{'Infant Voc Type','Adult Utt'}),:); %get only infant voc type and adult utt tier
    
    for k = 1:numel(Annots) %go through list of annotation sets
        %subset table for the required annotation set + exclude OLP (cuz 'OLP' will be counted by 'L' annot otherwise).
        CurrSubTab = CurrTab(contains(CurrTab.Annotation,Annots{k}) & ~contains(CurrTab.Annotation,{'OLP'}),:);
        NumSums(k) = NumSums(k) + height(CurrSubTab); %get number of utterances of kth annotation type for ith file
        DurSums(k) = DurSums(k) + (sum(CurrSubTab.EndTimeVal - CurrSubTab.StartTimeVal))/1000; %get duration, similarly. Div by 1000 to convert from ms to s
    end  
end

%----------------------------------------------------------
%This function gets the total number of CHNSP, CHNNSP, and AN (in that order) vocs that are fully overlapped with another voc (such that the voc in question is removed after olp 
% processing) and of vocs that partially overlapped (such that a portion of the voc is removed during olp processing) for a given file (CurrTab). This also requires the initial 
% input FullOlpCtr and PartialOlpCtr, which are both row vectors with a running sum of full and partial overlaps, cumulatively, upto the current file.
% We also input OlpProcFile, which is the post olp processing version of the current file; and PreOlpProcFile, which is the pre-olp processing version of the current file.
% The outputs, FullOlpCtr and PartialOlpCtr are row vectors with the first element corresponding to CHNSP, the second element to CHNNSP, and the third to AN, cumulatively, upto and 
% including details for CurrTab.
function [FullOlpCtr, PartialOlpCtr] = GetNumOfFullOlpAndPartialOlp(OlpProcFile,PreOlpProcFile,FullOlpCtr, PartialOlpCtr)

    AnnotList = {{'C','X'},{'R','L'},{'T','U','N'}}; %get list of annotations
    
    u_VocInd = unique(OlpProcFile.VocIndex); %get list of unique VocIndices (as a reminder, VocIndices track each distinct vocalisation before olp processing. That is, if, after Olp
    %processing, two chopped up vocs have the same VocInd, they are `inherited' from the same orginal voc from before olp processing
    
    for j = 1:numel(u_VocInd) %go through list of unique voc indices
        VI_Sub = OlpProcFile(OlpProcFile.VocIndex == u_VocInd(j),:); %subset for each unique voc index. This means that we get all `children' of each voc from before olp processing
        PreOlpProcSub = PreOlpProcFile(PreOlpProcFile.VocIndex == u_VocInd(j),:); %subset also for corresponding pre overlap processes file

        %check to make sure that there is only one voc correpsonding to one voc index in the table before olp processing.
        if height(PreOlpProcSub)~= 1
            error('One voc index in pre-olp processed file should correspond to one voc')
        end

        %Check if there is only one tier in the VI_Sub table. This is a check because vocs resulting from the same original voc should only have one tier type.
        if numel(unique(VI_Sub.TierTypeVec)) == 1 
            u_Annots = unique(VI_Sub.Annotation); %get list of unique annotations. If there is only 1 unique annotation and it is OLP, this means that the voc is fully overlapped
            %and we can increment the counter for the relevant label type (CHNSP, CHNNSP, AN) by 1.
            if numel(u_Annots) == 1 %check if there is only 1 annotation in list of unique annotations
                if isequal(u_Annots,{'OLP'}) %if the list of annotations is ALL OLP, then this means that this voc is fully overlapped. 
                    for k = 1:numel(AnnotList) %go through list of annotations to match to correct origianl utterance type (need to check againt corresponding Voc Index subtable
                        %from data table from b efore overlap processing
                        if contains(PreOlpProcSub.Annotation,AnnotList{k}) 
                            FullOlpCtr(k) = FullOlpCtr(k) + 1;
                        end
                    end
                end
            else %if there are more than one annotation type, this means that there is OLP and another annotation

                %more checks
                if ~contains(u_Annots,{'OLP'}) 
                    error('If there is more than one unique annotation, one of them has to be OLP')
                else
                    if numel(setdiff(u_Annots,{'OLP'})) ~= 1
                        error('If there is more than one unique annotations, after removing OLP from this set, there should only be one')
                    end
                end

                for k = 1:numel(AnnotList) %go through list of annotations to match to correct origianl utterance type (need to check againt corresponding Voc Index subtable
                    %from data table from before overlap processing
                    if contains(PreOlpProcSub.Annotation,AnnotList{k}) 
                        PartialOlpCtr(k) = PartialOlpCtr(k) + 1;
                    end
                end                       
            end
        else
            %If VI_Sub has more than one tier type vector, throw error.
            error('More than one tier')
        end
    end
end