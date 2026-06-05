function [] = CheckErrorsIn1msVocChunkFile(InputTab,OpTab) 

%This function checks for error in the process using which we get the human and LENA 5 min data chunked into 1 ms voc chunks we use for validation. The inputs here are the original file
% (without chopped into 1 ms chunks; InputTab), and the output table, WITH the 1 ms voc chunks (OpTab). This function does the following checks:
    % 1) that all 1 ms frames constituting a labelled utterance only has the label for that utterance.
    % 2) that all 1 ms frames constituing times between utterances are labelled 'NA-NotLab'.

%Note that these checks add more time to the analyses, so I would recommend ONLY using this function in the main file once to do these checks and to comment it out every other time.
% Also note that there is a total of 6 files where the unique speaker label (Uq_Spkr) for speaker labels for 1 ms frames spanning an utterance or speaker lables for 1 ms frames
% spanning the time between utterances is empty. This is because of the fine-grainness of the human-label annotation onsets and offsets, and can be circumvented by using an even smaller
% frame length (eg. 0.5 ms). However, this would add even more time to the computation and 12 total instances of this happening does not (in my opinion) warrant doing this.

u_Secnum = unique(InputTab.SectionNum); %get unique section number
for i = 1:numel(u_Secnum) %go through each section
    OpSubTab = OpTab(OpTab.SectionNum == u_Secnum(i),:); %subset the output and input tables for the section number (the output table has the 1 ms frames and the input table has the orginal
    %utternace onsets and offsets)
    IpSubTab = InputTab(InputTab.SectionNum == u_Secnum(i),:);

    %Check 1
    for j = 1:height(IpSubTab)
        if IpSubTab.xEnd(j)-IpSubTab.start(j) > 0 %if the utterance has a duration
            Uq_Spkr = unique(OpSubTab(OpSubTab.start >= IpSubTab.start(j) & OpSubTab.xEnd <= IpSubTab.xEnd(j),:).speaker); %pick out all 1 ms frames that span the onset and offset
            %of a given utterance (per the input table), then get unique speaker labels
            if numel(Uq_Spkr) > 1  %if there is more than one unique speaker label, throw error 
                error('More than one unique speaker label for 1 ms frames from utterance in question')
            elseif (~isempty(Uq_Spkr)) && (~strcmp(Uq_Spkr,IpSubTab.speaker(j)))%if the unique speaker label is different than the speaker label for the original utterance, throw error
                error('Utterance speaker label (per input table) does not match unique speaker label from 1 ms frames')
            end

            if isempty(Uq_Spkr)
                IpSubTab.FnameUnmerged(j) %Note that, if, in either check 1 or 2, a filename is output-ed at this point, it is likely that it is because of the fine-grainenes of the 
                %humanlistener annotation (As mentioned at the beginning of thsi function), so as long as this outout is associated with a function that generates the wraning message:
                % 'Warning: Input table not fully empty after going through all coding sheet sections for file xxx', we should be ok. Nevertheless, check to make sure that this is the case.
            end
        end
    end

    %Check 2
    for j = 1:height(IpSubTab)-1 %here, we look for the time between utterances, so ith end to (i+1)th start, ergo the indexing in the for loop.
        if IpSubTab.start(j+1)-IpSubTab.xEnd(j) > 0 %if there is time between subsequent utterances
            Uq_Spkr = unique(OpSubTab(OpSubTab.start >= IpSubTab.xEnd(j) & OpSubTab.xEnd <= IpSubTab.start(j+1),:).speaker); %pick out all 1 ms frames that span the time between the 
            % offset of ith utterance and onset of the next utterance, then get unique speaker labels
            if numel(Uq_Spkr) > 1 %if there is more than one unique speaker label, throw error 
                error('More than one unique speaker label for 1 ms frames between subsequent utterances')
            elseif (~isempty(Uq_Spkr)) && (~strcmp(Uq_Spkr,'NA-NotLab')) %if the unique speaker label is NOT NA-NotLab, throw error; the ~isempty condition is for cases when 
                %the between-utterances is just one frame (eg. i=13 for file list, section number 1, utterance indices 149-150).
                error('Unique speaker label for 1 ms frames between subsequent utterances is NOT NA-NotLab')
            end

            if isempty(Uq_Spkr)
                IpSubTab.FnameUnmerged(j)
            end
        end
    end
end