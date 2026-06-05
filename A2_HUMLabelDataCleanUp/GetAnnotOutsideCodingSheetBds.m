function [T_Final] = GetAnnotOutsideCodingSheetBds(CodingSpreadsheet,CsvDir,fileID,CsvFnRootSuffix)

%%@author info; June 2022; modified Nov 2023
%This script outputs a tabele file compiling info about eaf files that contains annotations outside of the spreadsheet bounds

%inputs: -CodingSpreadsheet (coding spreadsheet read in)
        %-CsvDir (list of csv files parsed from eaf files)
        %-fileID (initialised txt file with flags about different files written; see below for detalis)
        %-CsvFnRootSuffix (suffix or extension substring to delete from csv file name to get the file name root)

T_Final = array2table(zeros(0,12)); %initialise table to populate with annotations outside bounds
T_Final.Properties.VariableNames = {'StartTimeRef','StartTimeLineNum','EndTimeRef','EndTimeLineNum','AnnotId',...
                    'AnnotIdLineNum','Annotation','AnnotationLineNum','TierTypeVec','StartTimeVal','EndTimeVal','EafFname'};

for i = 1:numel(CsvDir)
    CsvFnRoot = erase(CsvDir(i).name,CsvFnRootSuffix); %get file name by removing appropriate sub string
    CorrespCodingSpreadSheet = CodingSpreadsheet(contains(CodingSpreadsheet.FileName,CsvFnRoot),:); %get corresponding coding sheet entriesx

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Error checkl block
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Checking to make sure that everything is read in correctly, whether
    %there are .eaf files without a corresponding spreadsheet entry and
    %vice-versa, etc
    if isempty(CorrespCodingSpreadSheet)
        fprintf(fileID,'No coding spreadsheet entry for this file for %s \n',CsvFnRoot);
                                    %DEBUGGING
                                    %         {strcat('i = ',num2str(i)),CsvFnRoot,CorrespOldFnRoot}
                                    %         CorrespCodingSpreadSheet
        CodingSpreadsheetStartTime = [];
        CodingSpreadsheetEndTime = [];
    else
        CodingSpreadsheetStartTime = CorrespCodingSpreadSheet.StartTimeSS;
        CodingSpreadsheetEndTime = CorrespCodingSpreadSheet.EndTimeSS;

%         %There is one entry in the coding spreadsheet whose StartTime isnt
%         %read in correctly, so we manually input it
%         for j = 1:numel(CodingSpreadsheetStartTime) 
%             if isnan(CodingSpreadsheetStartTime(j)) || isnan(CodingSpreadsheetEndTime(j))
%                 if (CodingSpreadsheetEndTime(j) == 23371) && (strcmp(CsvFnRoot,'0425_010611') == 1)
%                     CodingSpreadsheetStartTime(j) = (6*3600) + (24*60) + 31; %This start time dooesn't get read in, for some reason, so I am manually inputting this
%                                     %DEBUGGING
%                                     % strcat('i = ',num2str(i)),'; FnRoot is ',CsvFnRoot)
%                 end
%             end
%         end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    AnnotTable = readtable(CsvDir(i).name,'Delimiter',','); %read csv file with annotation details 
    IndexVec = (1:numel(AnnotTable.StartTimeVal))'; %vector of indices; transpose for column vector
    SegmentNum = zeros(size(IndexVec)); %vector to store the segment number for each 5 minute seg
    %Note that .eaf files have time in milliseconds. So, time in .eaf
    %file/1000 =  time in coding spreadsheet
    %Key table columns: StartTimeVal, EndTimeVal, StartTimeLineNum, EndTimeLineNum, AnnotationLineNum 
    %We will check which annotations fall in each segment. Then, we
    %identify annotations that fall outside of segments and store those in
    %a constantly updated table
    if ~isempty(CodingSpreadsheetStartTime) && ~isempty(CodingSpreadsheetEndTime) %if both have entries
        for j = 1:numel(CodingSpreadsheetStartTime)
            %pick out vocs within a section's start and end time limits and
            %assign section number, for each pair of start and end time. 
            %And assign 1 to all annoattions from each segment
            %We use the rather generous condition
            %that the first voc can start outside of the coding sheet start
            %time, as long as part of the voc is wihthin the coding sheet
            %section start and end times; and that the last voc can end
            %outside of the coding sheet end time, as long as it starts
            %before the coding sheet end time
            Indices = IndexVec((AnnotTable.EndTimeVal/1000 >= CodingSpreadsheetStartTime(j)) & (AnnotTable.StartTimeVal/1000 <= CodingSpreadsheetEndTime(j)));
            SegmentNum(Indices) = 1;
        end
    end

    if sum(SegmentNum) == 0 %if there are no annotations in the eaf file that fall within segment bounds
        fprintf(fileID,'All annotations outside of coding spreadsheet bounds %s \n',CsvFnRoot);
    end

    OutsideSegmentBounds = AnnotTable(~SegmentNum,:); %every row corresponding to annotations that don't fall in the bounds is extracted
    FileNameVec = cell(size(OutsideSegmentBounds.EndTimeVal)); %add file name column
    [FileNameVec{:}] = deal(CsvFnRoot);
    OutsideSegmentBounds.EafFname = FileNameVec; %append to table

    FileNameForLater{i,1} = CsvFnRoot;
    T_Final = [T_Final; OutsideSegmentBounds]; %append table with details about out-of-bounds annotations to larger table
end

%finally check if there are cases when there are no eaf files corresponding to coding spreadsheet sections
uCodingSpreadsheet_FnVec = unique(CodingSpreadsheet.FileName); %get unique file names from coding spreadsheet
for i = 1:numel(uCodingSpreadsheet_FnVec) %go through unique filenames
    CodingSpreadsheet_Fn = uCodingSpreadsheet_FnVec{i};
    if sum(contains(FileNameForLater,CodingSpreadsheet_Fn)) == 0 %check if there is an eaf file corresponding to the unique filename 
        %in coding spreadsheet. If not, an eaf file does not exist. 
        fprintf(fileID,'There is no .eaf file corresponding to coding spreadsheet entries for file %s \n',CodingSpreadsheet_Fn);
    end
end



