function [TableWithOverlapProcessed] = GetNonOverlapVocs(SortedSubTable,OverLapFlag)

%%@author info, July 2022

%Function To cut up vocs with overlap into non-overlapping chunks

%inputs: -SortedTable: table with infant voc type and adult utt dir vocs, sorted by start time
        %-OverLapFlag: vector with overlaping vocs flagged (1 for vocs that are overlapping, and 0 for vocs that aren't)

%output: Table with overlapping vocs chopped into overlapping and non-overlapping chunks  (to fully process the table, this function needs to be applied
%recursively; see algorithm below)

%algorithm: - For each target voc (TV) where overlap is indicated, there are 3 basic possible scenarios:
%1) Another voc ends within TV;
%2) another voc starts within TV; and
%3) All of TV is overlap. 
% There may be multiple vocs that start and end within TV, but if we look at the only the first start or end time occuring between TV's start and end 
% time, these are the only 3 possibilties. We will address overlaps recursively based on this basic 3-scenario structure: 
% First, we check if all of TV is overlap. To do this, we check whether there vocs that start before (or at the same time as) *and* end after (or at 
% the same time as) TV. If yes, we flag TV as OLP in he Annotation column. This means that TV is excluded from all subsequent analyses. Next, We check
% for whether a voc ends within TV by checking if the first intervening time between TV_st and TV_end is an end time. If yes, we remove TV up to the 
% end point. Then, we check for whether a voc starts within TV by checking if the first intervening time between TV_st and TV_end is a start time. If 
% yes, we chop off TV till that start time and deem it a separate voc, and everything after as a different voc. Note that in this process of chopping up
% TV, all chopped sub-vocs inherit TV's Voc Index, so we know all sub-vocs that constitute TV when it is time to stitch the vocs back together. 
% We do this for the whole list of vocs and re-test for overlap. We repeat this process till there are no more overlap flags.

%first check if overlap flag and sortedsubtable has the same number of rows
if numel(OverLapFlag) ~= numel(SortedSubTable.StartTimeVal)
    error('Dimension mismatch')
end

%initialise table that we will recursively add to with vocs processed for overlap
TableWithOverlapProcessed = array2table(zeros(0,size(SortedSubTable,2)),'VariableNames',SortedSubTable.Properties.VariableNames); 

for i = 1:numel(OverLapFlag) %go through overlap flag vector

    StraddleFlag = 0; %flag for whether a voc straddles TV

    if (OverLapFlag(i) == 1) && (strcmpi(SortedSubTable.Annotation{i},'OLP') ~= 1) %proceed if voc has an overlap and if voc has not alrady been tagged as a full overlap
        
        %get start and end times of all vocs that are not TV
        StartTime = [SortedSubTable.StartTimeVal(1:i-1); SortedSubTable.StartTimeVal(i+1:end)];
        EndTime = [SortedSubTable.EndTimeVal(1:i-1); SortedSubTable.EndTimeVal(i+1:end)];
        IndVec = (1:numel(StartTime))'; %get corresponding indices %make it a colun vector; Note that here, we now have a unique tag number identifying each vocalisation
        %(or chopped up sub-voc, if GetNonOverlapVocs has been applied multiple times already)

        %get TV start and end time
        TV_st = SortedSubTable.StartTimeVal(i); TV_end = SortedSubTable.EndTimeVal(i);

        %get start and end times of vocs that fall between TV_st and TV_end (excluding TV_st and TV_end). This includes vocs that may have start time = TV_st or end time = TV_end
        AllStBetween = StartTime(StartTime >= TV_st & StartTime < TV_end); %if vocs start before TV end
        AllEndBetween = EndTime(EndTime > TV_st & EndTime <= TV_end); %OR if vocs end after TV starts 
        StartEndTag = [ones(size(AllStBetween)); zeros(size(AllEndBetween))]; %create vector of tags for start (1) and end (0) times that fall between
        VocTag = [IndVec(StartTime >= TV_st & StartTime < TV_end)
            IndVec(EndTime > TV_st & EndTime <= TV_end)]; %Also get tags for each intervening voc, basically the index of these overlapping vocs. Note that if a voc starts and ends
        %within TV, it will appear twice in VocTag
        
        %clump AllStBetween and AllEndBetween into one vector and sort; and sort the tag vector in the same order
        [AllTimesBetween,I] = sort([AllStBetween; AllEndBetween]);
        StartEndTag = StartEndTag(I); VocTag = VocTag(I);

        %find if there are vocs that fully straddle TV (that is, vocs whose start is before TV and end is after TV)
        for j = 1:numel(StartTime)
            if (StartTime(j) <= TV_st) && (EndTime(j) >= TV_end)
                StraddleFlag = 1;
                break
            end
        end

        if StraddleFlag == 1 %first check if TV fully overlaps with another voc

            SortedSubTable.Annotation{i} = 'OLP'; %tag TV as OLP
            TableWithOverlapProcessed = [TableWithOverlapProcessed; SortedSubTable(i,:)]; %Add line for TV to growing table

        else %if TV does not fully overlap with another voc

            Line1 = SortedSubTable(i,:); %get line in table corresponding to TV
            Line2 = Line1; %get duplicate to store one of teh twp chopped voc bits

            if StartEndTag(1) == 1 %if the first intervening time is a start time

                %if the first intervening time (which is a start time AND the first entry in AllTimesBetween) is strictly between than TV_st and TV_end, chop
                %TV into TV_st to intervening start time, and intervening st time to TV_end
                if AllTimesBetween(1) > TV_st
    
                    %recast: the first chopped bit is TV_st to start of overlapping voc; assign start and end times
                    Line1.StartTimeVal(1) = TV_st;
                    Line1.EndTimeVal(1) = AllTimesBetween(1);
        
                    %the second chopped bit is the start of the overlapping voc to Tv_end. This will be edited down in the next iteration of this function's use in the main 
                    % file (This is because we don't know if the second part of TV, from the start of the overlapping voc to the end of TV, is fully overlapping or partially
                    % overlapping, etc).
                    Line2.StartTimeVal(1) = AllTimesBetween(1);
                    Line2.EndTimeVal(1) = TV_end;

                elseif AllTimesBetween(1) == TV_st %if intervening start time = TV_st

                    %find the end time of the intervening voc. To do this, we need to match the VocTag. First, remove the first intervening start time in question from
                    %AllTimesBetween. Assign InterveningVocTag as the VocTag of the intervening voc. And remove that first element from the VocTag vector. Now we can logical 
                    %index using InterveningVocTag and find the end time of the intervening voc in question
                    InterveningVocTag = VocTag(1);
                    AllTimesBetween = AllTimesBetween(2:end); VocTag = VocTag(2:end);
                    InterveningEndTime = AllTimesBetween(VocTag == InterveningVocTag); %Now, since each voc (or sub-voc, as the case maybe) has its own unique identifying tag,
                    %and since we have removed the start time of the intervening voc from this list, the only match with InterveningVocTag will correspond to the end time of
                    %the itervening voc 
                    
                    %recast: the first chopped bit is TV_st = intervening start to intervening voc end; assign start and end times. The reason this works is because we have
                    % already checked for an overlapping voc that straddles TV, so if there is an intervening start time = TV start time, then the intervening voc *has* to 
                    % end before TV ends.
                    Line1.StartTimeVal(1) = TV_st;
                    Line1.EndTimeVal(1) = InterveningEndTime;
                    Line1.Annotation{1} = 'OLP';
        
                    %the second chopped bit is the end of the overlapping voc to Tv_end. 
                    Line2.StartTimeVal(1) = InterveningEndTime;
                    Line2.EndTimeVal(1) = TV_end;
                end
            elseif StartEndTag(1) == 0 %if the first intervening time is an end time, then it has to srictle be between TV_st and TV_end. This is because if this 
            % end time = TV_end, then there has to be a corresponding start time between TV_st and TV_end. Otherwise the straddle flag would have caught it.                               
    
                %recast: the first chopped bit is TV_st to endt of overlapping voc; assign start and end times + tag this chopped bit as OLP
                Line1.StartTimeVal(1) = TV_st;
                Line1.EndTimeVal(1) = AllTimesBetween(1);
                Line1.Annotation{1} = 'OLP';
    
                %the second chopped bit is the end of the overlapping voc to Tv_end. This will be edited down in the next iteration of this function's use in the 
                % main file, in case there are more overlaps
                Line2.StartTimeVal(1) = AllTimesBetween(1);
                Line2.EndTimeVal(1) = TV_end;
            end

            %add the processed voc chunks to the growing table
            TableWithOverlapProcessed = [TableWithOverlapProcessed; Line1; Line2]; %re-constitute table
        end
    else %if (OverLapFlag(i) == 0)  %if there is no overlap, simply add voc to the growing table
        TableWithOverlapProcessed = [TableWithOverlapProcessed; SortedSubTable(i,:)];
    end
end

%finally, re-sort the table according to the start times
TableWithOverlapProcessed = sortrows(TableWithOverlapProcessed,'StartTimeVal');