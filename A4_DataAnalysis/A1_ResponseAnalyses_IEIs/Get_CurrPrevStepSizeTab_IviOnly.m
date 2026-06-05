function [CurrPrevStepSizeTab] = Get_CurrPrevStepSizeTab_IviOnly(ZscoreTab,SpkrType, OtherType, NAType, ResponseWindow)

% This function takes the table with step size info, and outputs a table with current and previous step size info, after marking steps associated with IVIs
% less than the ResponseWindow as NA response (note that this NA is different--but functionally the same--from the NA response when there is a target speaker onset within 
% the response window threshold after the last target speaker offset, without an intervening responder (OtherType) onset. The purpose of this NA tag is to 
% filter out IVIs that are less than the ResponseWindow for steps associated with a response, since steps associated without a response are, by definition 
% going to have IVIs greater than the ResponseWindow).

% Note that we DO not remove rows associated with NaN responses in this output table. We will do this in the R stats code AFTER we estimate residuals of the
% current step size ~ previous step size linear fit.
%
% Inputs: - ZscoreTab: the input table with acoustics, speaker labels, etc.
         %- SpkrType, OtherType, NAType: speaker labels that correspond to the target speaker, the other speaker (responder), and the speaker type that
            % triggers an NA response. For eg, if we are looking at AN response to CHNSP, thiese would be CHNSP, AN, and CHN, respectively
         %- ResponseWIndow: the response window vector (ResponseWindow) in seconds 
% Output: CurrPrevStepSizeTab: table with current and previous step size info as well as response info.

%get step size tab
[DistTab] = GetStepSizeTab_IviOnly(ZscoreTab,SpkrType,OtherType,NAType,ResponseWindow);
%variable names for DistTab are are [SectionNum, [response vars 0.5 to 10], InterVocIntVec]

OpNumCols = numel(ResponseWindow) + 2; %Number of columns for output table
for i = 1:numel(ResponseWindow) %go through response window vector and get response variable names for each response window value
    ResponseVarNames{1,i} = strcat('Response_',num2str(ResponseWindow(i)));
end
FinalVarNames = [ResponseVarNames ,'CurrIVI','PrevIVI']; %add the rest of the variable names 
if size(DistTab,1) <= 1 %if there are less than 2 step sizes
    CurrPrevStepSizeTab = array2table(zeros(0,OpNumCols)); %initialise output tab
    CurrPrevStepSizeTab.Properties.VariableNames = FinalVarNames;
    return
end

for i = 1:numel(ResponseWindow) %set responses for IVIs < response window values to NaN, for each response column
    CurrRespVarName = strcat('Response_',num2str(ResponseWindow(i))); %get variable name corresponding to each response window
    TempRespCol = DistTab.(CurrRespVarName); %get corresponding response column from DistTab
    TempRespCol(DistTab.InterVocInt <= ResponseWindow(i)) = NaN; %set responses associated with IVI less than ResponseWindow as NaN. Note that for AN
    %response to CHNSP, some NaNs are going to be associated with a CHNNSP onset within the response window threshold after the offset of a CHNSP sound, 
    %while other NaNs are going to be associated with CHNSP-to-CHNSP IVI being less than the responsewindow.
    DistTab.(CurrRespVarName) = TempRespCol; %recast the modified response vector as the relevant response column
end

%initialise output table
CurrPrevStepSizeTab = array2table(zeros(0,OpNumCols)); %initialise output tab
CurrPrevStepSizeTab.Properties.VariableNames = FinalVarNames; %set variable names for output table

%get var names for the current and prev step size parts of the final table
TabVarNames_Curr = strcat('Curr',{'IVI'}); 
TabVarNames_Curr  = [ResponseVarNames,TabVarNames_Curr]; %add Response as an additional var name to the current vars table    
TabVarNames_Prev = strcat('Prev',{'IVI'});
                        %                         % 
u_SecNum = unique(DistTab.SectionNum); %get unique section numbers

for i = 1:numel(u_SecNum) %go through each section number
    TempTab = DistTab(DistTab.SectionNum == u_SecNum(i),:);

    if size(TempTab,1) >= 2 %we need at least 2 steps in a section to get a set of current and prev step size for rthat section 
        Curr_TempTab = TempTab(:,2:end); %get currIvi col + all response cols (because response info is pertinent to currIVI)
        %Variable names for Curr_TempTab at this point are [[response vars 0.5 to 10], InterVocIntVec]
        Curr_TempTab = Curr_TempTab(2:end,:); %get rows corresponding to current IVI (so starting from the second row)
        Prev_TempTab = TempTab(:,end); %get PrevIvi cols
        %Variable names for Prev_TempTab at this point are [InterVocIntVec]
        Prev_TempTab = Prev_TempTab(1:end-1,:); %get rows corresponding to prev IVI (so starting from the second row)
    
        %recast var names
        Curr_TempTab.Properties.VariableNames = TabVarNames_Curr; %Variable names for Curr_TempTab at this point are [[response vars 0.5 to 10], CurrIVI]
        Prev_TempTab.Properties.VariableNames = TabVarNames_Prev; %Variable names for Curr_TempTab at this point are [PrevIVI]
    
        ProcessedTab = [Curr_TempTab Prev_TempTab]; %putb both togther
        %ProcessedTab = ProcessedTab(~isnan(ProcessedTab.Response),:);%remove NA responses
    
        CurrPrevStepSizeTab = [CurrPrevStepSizeTab; ProcessedTab]; %stack
    end
end

%checks: we are going to do the following checks, just to make sure that everything works as intended.
%1. now, let's check to make sure that NaN response steps ARE included
for i = 2:numel(ResponseWindow) %because minimum IVI is 0.6 s, so a response window of 0.5 s is not going to have an NA response, so start from response window = 1 s
    CurrRespCol = CurrPrevStepSizeTab.(ResponseVarNames{i});
    if numel(CurrRespCol) == numel(CurrRespCol(~isnan(CurrRespCol)))%if NaN responses and associated steps have been excludeed, then
        %the number of elements in Response vector before and after removing NaN responses will be the same. So, if this condition is satisfied, we know that NaN responses have already been 
        %excluded. However, the exception to this is if there are no NaN responses in the table (which could be possible for 5 min sections)
        DistTab
        disp('NaN responses and associated steps have already been removed from the table. OR this is a 5 min section')%if, for a response window value, this condition is true, 
        %display message and DistTab, and break
        break
    end
    
    %2. Finally, let's make sure that all IVIs less than or equal to response window are associated with NaN responses.
    ResponseForShortIvis = CurrRespCol(CurrPrevStepSizeTab.CurrIVI <= ResponseWindow(i)); %get Response values for Ivis <= response window
    if ~isempty(ResponseForShortIvis(~isnan(ResponseForShortIvis)))
        error('IVIs less than or equal to response window have not been flagged as associated with NaN response')
    end 
end