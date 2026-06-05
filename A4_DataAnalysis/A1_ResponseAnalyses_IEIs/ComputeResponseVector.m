function ResponseVector = ComputeResponseVector(StartTime, EndTime, SpeakerVec, SpeakerType, OtherType, NAType, IntervalTime)
                
%Ritwika VPS, Feb 2022
%UCLA, Dpmt of Comm

%function to compute response vector for both child and adult data

%Rule to determine responses: %If there is an onset (or start) of a vocalization by the OTHER speaker type within IntervalTime (in s) or less from the 
% offset (or end) of the SPEAKER type of interest. If so, a response is said to have occurred. If not, then if the 
% SPEAKER had a vocalization onset within IntervalTime or less from the offset of the SPEAKER, a response is not applicable. 
% Otherwise, a response is said not to have occurred.

%Inputs: - StartTime: start time vector for all AN and CHN (CHNSP, CHNNSP) vocs
        %- EndTime: end time vector for all vocs
        %- SpeakerVec: Vector containing speaker labels (CHNNSP, CHNSP, FAN and MAN)
        %- SpeakerType: Speaker type for which we want response data. 
        %- OtherType: Responder type(s) for which we want response data For example, if we want adult responses to CHNSP ONLY, then SpeakerType would be 
            % CHNSP and OtherType would be AN
        %- NAType: Voc type(s) which can trigger NA response. For example, if we want both CHNSP and CHNNSP following a CHNSP voc within 1 s without an 
            % intervening vocalisation to trigger an NA. For now, we will set NAType for AN responses to CHN(SP or NSP) as all CHN types
        %- IntervalTime: See Rule to determine responses above

%An error catching note (June 2, 2026): as the code was originally set up, the NaN initialisation resulted in some adult vocalisations being tagged as having NA responses
% by default when they were followed very closely by a CHNNSP voc. This is because previously, the code (starting with 'ResponseVector = NaN*ones(size(StartTime))') did not
% account for CHNNSP vocs. For CHNSP vocs, SpeakerType is CHNSP, OtherType is AN, and NAType is CHN, and therefore, this accounts for all voc types involved. For AN vocs, the
% SpeakerType is AN, OtherType is CHNSP, and NAType is AN, and this entirely skips over CHNNSP. The if loop immediately below this comment + the if loop at the end of the 
% function address this issue.

%------Conditional statement for when the target speaker is AN (edit on June 2, 2026)-----------------------------------------------------------------------------------
if contains(SpeakerType,'AN')
    FullResponseVector = NaN*ones(size(SpeakerVec)); %Initialise the full response vector for the entire speaker vector (i.e., the time series of speaker tags), so
    %it can be reconstituted (because the actual response computation is only happening for the speaker vector after CHNNSP is filtered out).
    OrigIndices = 1:numel(SpeakerVec); %Get the original indices to reconstitute

    %Filter out CHNNSP
    FilteredIndices = OrigIndices(~contains(SpeakerVec,'CHNNSP')); 
    StartTime = StartTime(~contains(SpeakerVec,'CHNNSP'));
    EndTime = EndTime(~contains(SpeakerVec,'CHNNSP'));
    SpeakerVec = SpeakerVec(~contains(SpeakerVec,'CHNNSP')); %do this last!

    %Error check
    if ~isempty(SpeakerVec(contains(SpeakerVec,'CHNNSP')))
        error('CHNNSP has not been filtered out')
    end
end
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

%The basic algorithm is to step through all vocs, and for each SpeakerType voc, find the following voc to see if response = Y, NA or N. 
ResponseVector = NaN*ones(size(StartTime)); %initalise response vector

for i = 1:numel(StartTime)-1 %(for all but the last voc)
    if contains(SpeakerVec{i},SpeakerType) == 1 %if current voc is relevant speaker type

        %find next voc type
        NextSpeaker = SpeakerVec{i+1};
        NextSpeakerStart = StartTime(i+1);
        CurrentSpeakerEnd = EndTime(i);

        CurrentEndToNextStartTime = abs(NextSpeakerStart - CurrentSpeakerEnd); %time between current speaker end and next speaker start

        if (contains(NextSpeaker,NAType)) && (CurrentEndToNextStartTime <= IntervalTime) %If next voc is within the time limit AND is the NAType speaker type, response is NaN (NA)
            ResponseVector(i) = NaN; %This is also redundant, since we start with an NaN vector, but again, keeping it in for my anxiety! 
        elseif (contains(NextSpeaker,OtherType)) && (CurrentEndToNextStartTime <= IntervalTime) 
            %If next voc is within the allowed time limite AND it is the other speaker type, response is YES (1)
            ResponseVector(i) = 1;
        elseif (CurrentEndToNextStartTime > IntervalTime) %finally, if the onset-offset difference is greater than interval time, response is NO (0)
            ResponseVector(i) = 0;
        end
    end
end

%------Conditional statement for when the target speaker is AN (edit on June 2, 2026)-----------------------------------------------------------------------------------
if contains(SpeakerType,'AN') %reconstitute the full response vector for the full speaker vector that includes CHNNSP
    FullResponseVector(FilteredIndices) = ResponseVector;
    ResponseVector = FullResponseVector; %Then, recast as output
end
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
                           