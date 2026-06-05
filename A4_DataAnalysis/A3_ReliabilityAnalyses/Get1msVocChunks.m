function [OpTab,NumAnnotSecs] = Get1msVocChunks(InputTab,CodingSubsheet,WarningOnOrOff,ErrorCheck)

%@author info, Jun 2024
%thsi function takes in the input table (with human or LENA speaker labels and onsets/offsets) as well as the portion of the coding spreadsheet relevant to the file, and
%makes everything in 1 ms increments +  adds 1 ms frames of NA speaker labels in between (for unlabelled portions in the case of human listener labels, and all other label
% types which we are not considering in our study, in the case of LENA labels. For the latter case, this includes labels such as SIL, OLN, MAF, CXN, etc.).
% The input WarningOnOrOff simply toggles warnings on or off in the function that returns 1 ms frames ONLY (we only want the warnings issues the first combo of:
    % 1. section level vs file level error computing, and 2. all adult vocs or child directed adult vocs only, as labelled by the human listener.
%The input ErrorCheck is a logical input which, when TRUE, implements checks to make sure that the 1 ms voc chunk generation works as intended, using the user-defined function 
% CheckErrorsIn1msVocChunkFile.

%The outputs are the table with 1 ms increment labels, onsets, and offsets, as well as all other variables in the input table; and the number of sections that have been actally annotated
% in teh file.
InpVarNames = InputTab.Properties.VariableNames; %get variable names for input table

if ErrorCheck
    IpTabCopy = InputTab; %copy of the input table for errorcheck (because the original input table gets setdiff-d into empty by the end of this function, which is when we check for errors).
end

%remove obsolete columns
if ~isempty(InpVarNames(contains(InpVarNames,'wavfile'))) 
    InputTab = removevars(InputTab,'wavfile');
end
if ~isempty(InpVarNames(contains(InpVarNames,'Annotation')))
    InputTab = removevars(InputTab,'Annotation');
end
if ~isempty(InpVarNames(contains(InpVarNames,'SubrecEnd')))
    InputTab = removevars(InputTab,'SubrecEnd');
end

NumAnnotSecs = 0; %initialise number of annotated sections
OpTab = array2table(zeros(0,width(InputTab))); OpTab.Properties.VariableNames = InputTab.Properties.VariableNames;%initialise output table and set variable names

for i = 1:height(CodingSubsheet) %go through 5 minute section per coding subsheet

    CodingSheetStart = CodingSubsheet.StartTimeSS(i); CodingSheetEnd = CodingSubsheet.EndTimeSS(i); %get start and end times of section from coding spreadsheet
    %subset input table using start and end times in coding spreadsheet for the labelled section. Note that we are allowing all vocs that end after coding spreadsheet start time
    % and start before coding spreadsheet end time.
    SubTab = InputTab(InputTab.xEnd >= CodingSheetStart & InputTab.start <= CodingSheetEnd & contains(InputTab.FileNameUnMerged,CodingSubsheet.FileName{i}),:);
    CorrespSecNum = unique(SubTab.SectionNum); %get section number
    CorrespFnameUnmerged = unique(SubTab.FileNameUnMerged); %get unmerged subrec file name
    if (numel(CorrespSecNum) > 1) && (WarningOnOrOff == 1) %check if one section in coding spreadsheet has only one section number in the inpout table
        warning('One start-end time pair from coding spreadsheet corresponds to more than one section in the data table: %s',SubTab.FileNameUnMerged{1})
    end
    if (numel(CorrespFnameUnmerged) > 1) && (WarningOnOrOff == 1) %check if one section number in the inpout table has more than odata form ne unmerged file name (ie. at the subrec level)
        warning('Section %i in the data table has data from more than one subrec: %s',SubTab.SectionNum(1),SubTab.FileNameUnMerged{1})
    end
    
    InputTab = setdiff(InputTab,SubTab); %remove subsetted rows from the input table (so we can test if after all sections--per coding spreadsheet--have been id'd, the inoput table
    %is empty); 

    if ~isempty(SubTab) %if the section has been annotated, the subsetted table will have rows
        NumAnnotSecs = NumAnnotSecs + 1; %increment
        Times = (CodingSheetStart:0.001:CodingSheetEnd)'; %get 1 ms frames for the 5 minute section in question (per coding sheet)
        StartTimes = Times(1:end-1); EndTimes = Times(2:end); %get vectors of start and end times for this 1 ms breakdown
        SecNumVec = CorrespSecNum*ones(size(StartTimes)); %get section number vector for this
        FnameUnmergedTemp = cell(size(EndTimes)); FnameUnmergedTemp(1:end) = CorrespFnameUnmerged; %get cell array populated with unmerged filename
        SpeakerTemp = cell(size(EndTimes)); SpeakerTemp(1:end) = {'NA-NotLab'}; %initialise Speaker label cell array to populate; here, 'NA-NotLab' indicates all frames that don't have a label
        %as far as our analyses are concerned
        IndVec = 1:numel(StartTimes); %get vector of indices to assign relevnt speaker labels
        for j = 1:numel(SubTab.speaker) %go through speaker labels in input subsetted table
            TempInd = IndVec(StartTimes >= SubTab.start(j) & EndTimes <= SubTab.xEnd(j)); %pick out all frames that constituite a given utterance
            SpeakerTemp(TempInd) = SubTab.speaker(j); %assign that speaker label to all those frames. The rest will simply have the NA-NotLab label
        end

        T_Temp = table(SpeakerTemp,StartTimes,EndTimes,FnameUnmergedTemp,SecNumVec); %make table for the section
        T_Temp.Properties.VariableNames = OpTab.Properties.VariableNames; %assign variable names
        OpTab = [OpTab; T_Temp]; %add to final output table
    end
end

%Checks: Check if input table is now empty after having all sections removed. Also check if there are unannotated sections. 
% NOTE: I have looked at these instances, and they consist of at most one 1 ms frame per section (for less than 10 sections in total across files) where the frame falls 1 ms outside the 
% limits in the coding spreadsheet. This is because we allow for annotated vocs that have part of the duration of the voc in the designated 5 minute section in our analyses, in order to not 
% truncate a voc.
if (~isempty(InputTab)) && (WarningOnOrOff == 1)
    warning('Input table not fully empty after going through all coding sheet sections for file %s\n',InputTab.FileNameUnMerged{1})
    InputTab
end

if ErrorCheck
    CheckErrorsIn1msVocChunkFile(IpTabCopy,OpTab)  
end
