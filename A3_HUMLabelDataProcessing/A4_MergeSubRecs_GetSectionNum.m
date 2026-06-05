clear; clc

%%@author info, July 2022; updated Dec 2023

%This script joins together 5 min sections files that are from the same day-long recording, and identifies data with its own section number.
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------  
%define paths, etc. CHANGE PATHS AND STRINGS IN FUNCTION CALLS AS NECESSARY

%we also make note of files that have more or less than three 5-min sections annotated, then we check this against the coding spreadsheet to see if the not-equal-to three
% 5-min sections is built into the coding spreadsheet for that file or not. 
%first, read in coding spreadsheet. This has info about which 5-minite sections were intended to be annotated from each day-long recording.
cd '/~/BaseDataPath/Data/HUMLabelData/A1_HUMLabelData_CleanupPipeline/SummaryCsvAndTxtFiles/'
CodingSheet = readtable('FNSTETSimplified.csv');

BasePath = '/~/BaseDataPath/Data/';
destinationpath = strcat(BasePath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A6_TSwSubrecsMerged/');

%go to folder with Acoustics data (overlaps processed for acouistics and then vocs stitched back together + with annotation tags, and get relevant files.
TSpath = strcat(BasePath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A5_HlabelTS_OlpRemoved/'); 
cd(TSpath); 
TSFiles = dir('*_TS_OlpRemoved.csv');

%go through TS files and get file roots (with and without section numbers, a, b, etc.)
for i = 1:numel(TSFiles)
    FnRoot{i,1} = regexprep(strrep(TSFiles(i).name,'_TS_OlpRemoved.csv',''),'[a-z]+','');
    FnRoot_wSubRecInfo{i,1} = strrep(TSFiles(i).name,'_TS_OlpRemoved.csv','');
end
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------  

%Get unique file name roots, so all the files with the same file root but are from different subrecs (indicated by suffixes a, b, etc) can be merged
U_FnRoot = unique(FnRoot); 

%go through unique filename roots and match root name to full file names
for i = 1:numel(U_FnRoot)
    T_new = GetSubrecsStitchedTab(U_FnRoot{i},TSpath,FnRoot_wSubRecInfo,CodingSheet);

    %re-compute duration as the difference between end and start of a voc (some durations from the acoustics TS code have NaN values because the 
    % corresponding pitch and/or amplitude could not be calculated)
    Duration = T_new.xEnd - T_new.start;
    if ~isempty(Duration(Duration <= 0)) %check that there are no negative or 0 durations
        error('Zero or negative durations present')
    end
    T_new.duration = Duration; 

    writetable(T_new,...
        strcat(destinationpath,U_FnRoot{i},'_TSSubrecMerged.csv')); %write table to destination
    
    NumSectionsInHum(i,1) = numel(unique(T_new.SectionNum)); %Get # 5 min sections in the file
end

%get unique filenames (excluding subrec suffixes) and the number of sections intended to be annotated from each day-long recording. Note that we don't have to check for annotations
% outside coding spreadsheet bounds because we have cleaned up all annotations outside coding spreadsheet bounds in trhe human-labelled data.
U_CodingSheetFname = unique(regexprep(CodingSheet.FileName,'[a-z]+','')); %remove subrec suffixes

%'0776_000613' was annotated wrt an incorrect audio file, and we exclude this from further analyses. So, this file is not going to be present in U_FnRoot. However, thsi is 
% going to be the only file name that is not present in U_FnRoot, so remove that from teh list of unique file names (exluding subrec suffixes) from the coding spreadsheet. 
U_CodingSheetFname = setdiff(U_CodingSheetFname,'0776_000613');
%Next, check to make sure that the list of unique file names are the same for the TS files and from the coding spreadsheet (after excluding 0776_000613).
if ~isequal(U_CodingSheetFname,U_FnRoot) 
    error('List of unique file name roots (excluding subrec suffixes) from coding spreadsheet (after excluding 0776_000613) and the list of TS .csv files NOT same.')
end

for i = 1:numel(U_CodingSheetFname) %get number of sections intended to be annotated for each file, per coding spreadsheet
    NumSectionsInCodingSheet(i,1) = numel(CodingSheet.FileName(contains(CodingSheet.FileName,U_CodingSheetFname{i})));
end

NumAnnotSecDiff = NumSectionsInCodingSheet - NumSectionsInHum; %the assumption is that the number of annotated sections shouldn't be greater than the number of sections
%intended for annotation per the coding sheet. So, this difference should always be positive or zero
Fname_UnannotSections = U_FnRoot(NumAnnotSecDiff ~= 0); %pick out file names, number of actual annotated sections, and number of sections intended to be annotated
%for cases where the number of sections intended to be annotated and the number of sections actually annoatated are not the same
NumSectionsToAnnot_CodingSheet = NumSectionsInCodingSheet(NumAnnotSecDiff ~= 0);
NumSectionsAnnotated = NumSectionsInHum(NumAnnotSecDiff ~= 0);
if ~isempty(NumAnnotSecDiff(NumAnnotSecDiff < 0))
    error('More 5 min sections annotated than intended per coding spreadsheet for this file.')
end

T_Annotdetails = table(Fname_UnannotSections,NumSectionsToAnnot_CodingSheet,NumSectionsAnnotated); %get this info into a table and write table
writetable(T_Annotdetails,strcat(BasePath,'MetadataFiles/FilesWithUnannotatedSections.csv'));

%get info about files where 5 min sections are less than 30 minutes apart
TimeBnSections_Flag = 0; %initialise flag counter
if ~strcmp(setdiff(unique(CodingSheet.FileName),FnRoot_wSubRecInfo),'0776_000613') %accounting for '0776_000613' being excluded
    error('The set of unique filenames (with subrec info) per coding spreadsheet and from list of files dir-d are not the same.')
end
for i = 1:numel(FnRoot_wSubRecInfo) %go through unqiue file names with subrec info
    CodingSubTab = sortrows(CodingSheet(contains(CodingSheet.FileName,FnRoot_wSubRecInfo{i}),:),'StartTimeSS'); %subset table with info for relevant file, and sort rows in incresing start time
    TimeBnSections = (CodingSubTab.StartTimeSS(2:end) - CodingSubTab.EndTimeSS(1:end-1))/60; %get time between sections (in minutes)
    if ~isempty(TimeBnSections(TimeBnSections < 30)) %check if there are any sections that are less than 30 minutes apart
        TimeBnSections_Flag = TimeBnSections_Flag + 1; %increment flag counter
        Num_TimeBnSectionsLessThan30min(TimeBnSections_Flag,1) =  numel(TimeBnSections(TimeBnSections < 30)); %number of instances where sections are less than 30 minutes apart
        Fname_TimeBnSectionsFlag{TimeBnSections_Flag,1} = FnRoot_wSubRecInfo{i};
    end
end

writetable(table(Fname_TimeBnSectionsFlag,Num_TimeBnSectionsLessThan30min),strcat(BasePath,'MetadataFiles/FilesWithLessThan30minBnSections.csv')) %write teble

%---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
% %The following was written to check if there are recorder pauses during sections. As of now, there aren't, so I am commenting this out. You can
% %uncomment it if you want to check for yourself. PLEASE UNCOMMENT AS NECESSARY
% 
% %now check if any sections have pauses. First, get relevant path
% PauseTimePath = '/~/BaseDataPath/Data/LENAData/A3_PauseTimes/';
% 
% for i = 1:numel(FnRoot_wSubRecInfo) %go through vector with file name roots with subrec info
% 
%     PauseTab = readtable(strcat(PauseTimePath,FnRoot_wSubRecInfo{i},'_PauseTimes.txt'),'Delimiter','\t'); %Read out relevant pause time file
%     if ~isfile(strcat(PauseTimePath,FnRoot_wSubRecInfo{i},'_PauseTimes.txt')) %if the file does not exist, display file name
%         FnRoot_wSubRecInfo{i}
%     end
% 
%     if isempty(PauseTab) == 0 %if there ARE pauses
%         HumTab = readtable(strcat(destinationpath,...
%             regexprep(FnRoot_wSubRecInfo{i},'[a-z]+',''),...
%             '_TSSubrecMerged.csv')); %read in corresponding data table
%         PauseEndTime = PauseTab.Var2; %get times at which recorder was apused
% 
%         NumSections = unique(HumTab.SectionNum); %get number of sections in the file
%         Ctr = 0; 
%         SecStart = []; SecEnd = [];
%         for j = 1:numel(NumSections)
%             %subset table for each section number which also corresponds to the subrec in questiin
%             SubTab = HumTab(HumTab.SectionNum == NumSections(j) & contains(HumTab.FileNameUnMerged,FnRoot_wSubRecInfo{i}),:);
%             if ~isempty(SubTab) %if the sub-setted table is not empty
%                 Ctr = Ctr + 1;
%                 SecStart(Ctr) = min(SubTab.start); SecEnd(Ctr) = max(SubTab.xEnd); %get start and end times of secton
%             end 
%         end
% 
%         if ~isempty(SecStart) %if the vector start times of section exists
%             for k = 1:numel(SecStart)
%                 for l = 1:numel(PauseEndTime)
%                     %check if there is a pause time between start and end of a section
%                     if (PauseEndTime(l) > SecStart(k)) && (PauseEndTime(l) < SecEnd(k))
%                         FnRoot_wSubRecInfo{i}
%                     end
%                     %as it turns out, there aren't any pauses, so I am not writing code to analyse that condition
%                 end
%             end
%         end
%     end  
% end
%---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function [T_Op] = GetSubrecsStitchedTab(U_FnRoot_i,TSpath,FnRoot_wSubRecInfo,CodingSheet)

%this function takes a unique file name root (without suffixes for subrecs; eg. 0973_000901), reads in all TS files with matching filename roots (including subrec suffixes, if any),
% stitches the subrec files together (if any), adds info about the filename before this merging (so that we can identify which subrec file the data comes from), and adds info about 
% separate 5 minute sections. So, if 0973_000901 has 2 subrecs, 0973_000901a and 0973_000901b, and a total of three 5-min sections annotated, this function will read in both and stitch 
% them together, add a vector to the table identifying what data came from 0973_000901a and 0973_000901b, and also adds a vector identifying the three separate 5 min sections.

%The output is the final table from this process (T_Op)

%inputs are the file name root in question (U_FnRoot_i); the file path for the TS tables saved after OLP processing and stitching back together chopped up overlapping vocs (TSpath);
% the vector with filename roots with subrec info suffixes; and the Coding spreadsheet.

    Files_w_SameFnRoot = FnRoot_wSubRecInfo(contains(FnRoot_wSubRecInfo,U_FnRoot_i)); %get all subrec file names with the same filename root

    if numel(Files_w_SameFnRoot) == 1 %if there is only one file that has the file name root in question, then we don't need to stitch anything together. However, we do need to add
        % info about the original file name (so that the final tables for cases with subrecs and without subrecs, have the same columns).
        TStab = readtable(strcat(TSpath,Files_w_SameFnRoot{1},'_TS_OlpRemoved.csv'),'Delimiter',',');
        [OrigFnameVec{1:numel(TStab.speaker)}] = deal(Files_w_SameFnRoot{1}); %create cell array to store name of orig file
        TStab.FileNameUnMerged = OrigFnameVec'; %add to table
    elseif numel(Files_w_SameFnRoot) > 1 %if there is more than one file has the same file name root (indicating more than one subrec), we need to sticth them together
        TStab = readtable(strcat(TSpath,Files_w_SameFnRoot{1},'_TS_OlpRemoved.csv'),'Delimiter',','); %read in the first subrec file
        [OrigFnameVec{1:numel(TStab.speaker)}] = deal(Files_w_SameFnRoot{1}); %create cell array with subrec file name
        for j = 2:numel(Files_w_SameFnRoot) %loop through the rest of the subrec files
            TSTabToAdd = readtable(strcat(TSpath,Files_w_SameFnRoot{j},'_TS_OlpRemoved.csv'),'Delimiter',','); %read in file
            TStab = [TStab; TSTabToAdd]; %add to table
            [OrigFnameVec{end+1:end+size(TSTabToAdd,1)}] = deal(Files_w_SameFnRoot{j}); %add subrec file name to cell array
        end
        TStab.FileNameUnMerged = OrigFnameVec'; %append column to table
    elseif numel(Files_w_SameFnRoot) < 1 %if there are no matching files, throw error
        error('There are no files corresponding to FnRoot')
    end

    SectionNumVec = zeros(size(TStab.start)); %initialise vector to store section number info in
    IndexVec = (1:numel(TStab.start))'; %initialise column vector with indices 

    %Now, we assign section numbers to utterances, based on section start and end times per the coding spreadsheet. First, subset coding spreadsheet info for the filename.
    CodingSubTab = CodingSheet(contains(CodingSheet.FileName,U_FnRoot_i),:);
    for j = 1:numel(CodingSubTab.StartTimeSS) %go through each pair of section start and end time
        TempIndVec = IndexVec((TStab.xEnd >= (CodingSubTab.StartTimeSS(j)-1)) & (TStab.start <= (CodingSubTab.EndTimeSS(j)+1))); %pick out all utterances that have any portion between the
        %coding spreadsheet start and end time for a given section, and designate indices for all those utterances with the same section number (see next line) Note that I am providing a 1 second 
        % buffer to the coding spreadsheet end and start times to account for any sub-vocs that might fall outside of the bounds after being chopped up into overlapping and non-overlapping subvocs.
        SectionNumVec(TempIndVec) = j;
        %Note that the section number is the same value as the index of the annotated 5 minute section in the coding spreadsheet (based on the section start time sorted in
        % ascending order). This means that if only, say, the 2nd section is annotated, then the file will only have one section with section number = 2.
    end

    if ~isempty(SectionNumVec(SectionNumVec == 0))
        %TStab(SectionNumVec == 0,:) %DEBUGGING BIT
        %CodingSubTab
        error('There are utterances that do not belong to any section in the coding spreadsheet')
    end

    TStab.SectionNum = SectionNumVec; %add section number info to table

    %Check to make sure that a section only contains vocs from a single (unmerged) file.
    U_SecNums = unique(TStab.SectionNum); %get unique section numbers
    for i = 1:numel(U_SecNums)
        TS_secnum_i = TStab(TStab.SectionNum == U_SecNums(i),:); %subset table
        Curr_FnameUnmerged = unique(TS_secnum_i.FileNameUnMerged); %get unique unmerged file names for subsetted table
        if numel(Curr_FnameUnmerged) ~= 1
            error('Number of unique unmerged file names in a 5-minute section is not 1')
        end
    end

    T_Op = TStab; %assign output
end
