function [DistTab] = GetStepSizeTab_IviOnly(InputTab,SpkrType,OtherType,NAType,ResponseWindow)

%This function computes intervocalisation interval vector based on input table, and responses for each one of the specified response window values in the input ResponseWindow vector. 
% It also removes step size entries associated with the end of a subrecording. The output is a table with the IVI, section number, and the responses for each response window value.

%Inputs: - InputTab: a table that contains (at the very least) columns ('logf0_z','dB_z','logDur_z','start','xEnd', 'speaker', and either 'SubrecEnd' or 'SectionNum').
        %- SpkrType, OtherType, NAType: speaker labels that correspond to the target speaker, the other speaker (responder), and the speaker type that
            % triggers an NA response. For eg, if we are looking at AN response to CHNSP, thiese would be CHNSP, AN, and CHN, respectively
        %- ResponseWIndow: the vector of response window times (ResponseWindow) in seconds

%check to make sure that SpkrType, OtherType, and NAType inputs are acceptable strings
if sum(strcmpi(SpkrType,{'CHNSP','CHNNSP','CHN','AN'})) == 0
    error('Incorrect SpkrType string')
end

if sum(strcmpi(OtherType,{'CHNSP','CHNNSP','CHN','AN'})) == 0
    error('Incorrect OtherType string')
end

if sum(strcmpi(NAType,{'CHNSP','CHNNSP','CHN','AN'})) == 0
    error('Incorrect NAType string')
end

OpNumCols = 13; %Number of columns in output table

if size(InputTab,1) <= 1  %mandatory checks ; if there is only one row, then this whole exercise is pointless.
        DistTab = array2table(zeros(0,OpNumCols)); 
    return
end

%get section number info if applicable
InputTabVarNames = InputTab.Properties.VariableNames;
if isempty(InputTabVarNames(contains(InputTabVarNames,'SectionNum'))) %if there is NO column with section num info
    InputTab.SectionNum = GetSectionNumVec(InputTab); %get section number information, and add section number information to InputTab
end

for i = 1:numel(ResponseWindow) %go through response window vector
    RespVarName{1,i} = strcat('Response_',num2str(ResponseWindow(i))); %get the name for the table column for each response window value
    InputTab.(RespVarName{i}) = ComputeResponseVector(InputTab.start,InputTab.xEnd,InputTab.speaker,SpkrType,OtherType,NAType,ResponseWindow(i)); %compute response and 
    %assign to table
    %(At this point, the variable names in InputTab are [[variable names in the orginal input table], [Response vars 0.5 to 10]]).
end
InputTab = InputTab(contains(InputTab.speaker,SpkrType),:); %filter by speaker type

if size(InputTab,1) <= 1 %check again if the filtered inputtab is empty
    DistTab = array2table(zeros(0,OpNumCols));
    return
end
                                                    
InterVocIntVec = []; %empty vector to store intervoc intervals

%create empty table to store the rest of the info needed, after removing redundant or unnecessary cols
RestOfTab = array2table(zeros(0,(numel(ResponseWindow) + 1))); %we need as many columns as there are response windows + one more for the section number 
RestOfTab.Properties.VariableNames = ['SectionNum',RespVarName]; %This retains the section number column followed by the response variables columns

U_SectionNumVec = unique(InputTab.SectionNum); %get unique section numbers

for i = 1:numel(unique(U_SectionNumVec)) %go through each unique section and get step sizes. This way, we don't add step sizes between subrecs

    Section_SubTab = InputTab(InputTab.SectionNum == U_SectionNumVec(i),:); %pick out rows with the same section number

    %now, if a section only has one row of elements, then we cannot compute a step size
    if size(Section_SubTab,1) >= 3 %if there are at least three rows (because, we need at least two utterance events to get a step size, and two step sizes to get one
        %set of current and previous step size)
    
        InterVocIntVec  = [InterVocIntVec ; Section_SubTab.start(2:end) - Section_SubTab.xEnd(1:end-1)]; %inter voc interval
    
        %get rest of the table to add to DistTab, after the end of the loop. Note that the last entry in each  column has to be removed, since this isn't going 
        %to be associated with a step size
        Section_SubTab = Section_SubTab(:,RestOfTab.Properties.VariableNames); %only retain variable names specified by RestOfTab
        RestOfTab = [RestOfTab; Section_SubTab(1:end-1,:)];
    end
end

%add additional step size columns
RestOfTab.InterVocInt = InterVocIntVec; %add inter voc interval
%(At this point, the variable names are [SectionNum, [response vars 0.5 to 10], InterVocIntVec] ).
DistTab = RestOfTab;

                                    


