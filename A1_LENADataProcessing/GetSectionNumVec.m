function SectionNumVec = GetSectionNumVec(InputTab)

%This function generates a section number vector, that contains information about the section an utterance belongs to. So, all vocs upto the end of the
%first subrec will be tagged 1, all vocs from the start to end of the second subrec will be tagged 2, etc. This is so that the information from
%the Subrecend column of the input table is copied into a more, shall we say, robust SectionNumVec vector, so that even if we filter by speaker type, 
% we have information about whether 2 utterances are part of the same subrec or not. 

%Note that the way the data pre-processing is set up, only the day-long LENA data is put through this section number determining step, and as such, is the only data type that has a
% SubrecEnd column in the datatable.

if isempty(InputTab.SubrecEnd) %check for empty
    SectionNumVec = [];
    return
else
    %based on subrecend, generate SectionNumVec: basically, a vector identifying the section number the voc belongs to, if there are subrecs in the recording
    SectionNumValue = 1; %default
    SectionNumVec = zeros(size(InputTab.SubrecEnd)); %initialise
    for j = 1:numel(InputTab.SubrecEnd)
        SectionNumVec(j) = SectionNumValue;
        if InputTab.SubrecEnd(j) == 1
            SectionNumValue = SectionNumValue + 1; %if current voc is end of a subrec, increment section number value
        end
    end
end