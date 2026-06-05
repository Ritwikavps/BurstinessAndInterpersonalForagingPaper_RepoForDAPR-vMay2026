function [OlpFlag] = DetectOverlap(SortedTable)

%%@author info, July 2022

%Function to get a flag vector flagging overlapping voc (OlpFlag); this flag vector has the same number of rows as the input table (SortedTable)

%Input: SortedTable - table with infant voc type and adult utt dir vocs, sorted by start time of the utterance
%Output: OlpFlag - a vector that flags utterances that have some overlap with at least one other utterance (flagged as 1); if the utterance has no
        %overlap, the corresponding entry in the OlpFlag vector is 0

% The idea is that we go through the list of sorted start times, and for the i-th start time, we get the list of vocs i to the last voc in the table.
% Then, we check if any subsequent vocs overlap with the i-th voc, by checking if any subsequent voc has a start time before the end time of the i-th
% voc. If yes, we flag both the i-th voc and all vocs with a start time before the end time of the i-th voc as OLP = 1. This way, we  sequentially check
% if every voc has other vocs that overlap with it, and therefore, don't let anything slip through the cracks. In particular, even though for each i-th
% voc, we only check if vocs (i+1) through the last vocalisation in the table overlap with the i-th voc, we also tag all vocs overlapping with the i-th
% voc as having an overlap. This way, if the (i+1)th voc only overlaps with the i-th voc, that info isn't lost when we go to check if the (i+1)th voc
% has an overlap with any subsequent voc.

%Initialise OlpFlag vector as well as the vector to store start times (TempStartTime) to be updated by removing the i-1th start time (the rationale for this is given above)
OlpFlag = zeros(numel(SortedTable.StartTimeVal),1);
IndVec = 1:numel(SortedTable.StartTimeVal); %Get IndVec, which is the vector of indices corresponding to the rows of SortedTable.

for j = 1:numel(SortedTable.StartTimeVal) %go through vocs to see which ones overlap

    TempTab = SortedTable(j:end,:); %subset table with current voc through to the last voc in table
    TempIndVec = IndVec(j:end); %subset IndVec as well, so we can flag the indices of vocs that have overlaps with current voc
    TempTab.StartTimeVal(1) = Inf; %set the current start time to infinity. This way, the start time of the current voc will not be flagged as overlapping

    OlpIndex = TempIndVec(TempTab.StartTimeVal < TempTab.EndTimeVal(1)); %Pick out indices of any subsequent vocs whose start times (the current voc is excluded
    %from this check since we have set the current start time to infinity) fall before the end of current voc
    if ~isempty(OlpIndex) %if OlpIndex is not empty
        OlpFlag(j) = 1; %flag cureent voc as having overlap
        OlpFlag(OlpIndex) = 1; %flag overlappoing vocs as well  
    end
end
