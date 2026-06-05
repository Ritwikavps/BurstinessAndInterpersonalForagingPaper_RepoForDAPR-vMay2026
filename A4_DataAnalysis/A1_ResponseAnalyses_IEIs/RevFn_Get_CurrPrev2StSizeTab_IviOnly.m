function [CurrPrev2StepSizeTab] = RevFn_Get_CurrPrev2StSizeTab_IviOnly(ZscoreTab,SpkrType, OtherType, NAType, ResponseWindow)

% Dec 2025
% This is part of additional analyses code being written for the Burstiness paper in response to reviewer comments (however, I am preserving the 'step size' language as 
% opposed to IEI in function names etc for continuity with the rest of the code.

% This function takes the table with the step size info, and outputs a table with current step size(i), previous step size (i-1), and step size before the previous step size (i-2), 
% after marking (current) steps associated with IVIs less than the ResponseWindow as NA response (note that this NA is different--but functionally the same--from the NA 
% response when there is a target speaker onset within the response window threshold after the last target speaker offset, without an intervening responder (OtherType) onset. 
% The purpose of this NA tag is to filter out IVIs that are less than the ResponseWindow for steps associated with a response, since steps associated without a response are, 
% by definition going to have IVIs greater than the ResponseWindow).

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
%variable names for DistTab are are [SectionNum, [response vars 0.5 to 10], InterVocInt]

OpNumCols = numel(ResponseWindow) + 3; %Number of columns for output table
for i = 1:numel(ResponseWindow) %go through response window vector and get response variable names for each response window value
    ResponseVarNames{1,i} = strcat('Response_',num2str(ResponseWindow(i)));
end
FinalVarNames = [ResponseVarNames ,'CurrIVI','PrevIVI','Prev2IVI']; %add the rest of the variable names 
if size(DistTab,1) <= 2 %if there are less than 3 step sizes (cuz you need at least 3 step sizes for getting the prev and previous-to-previous IVI)
    CurrPrev2StepSizeTab = array2table(zeros(0,OpNumCols)); %initialise output tab
    CurrPrev2StepSizeTab.Properties.VariableNames = FinalVarNames;
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
CurrPrev2StepSizeTab = array2table(zeros(0,OpNumCols)); %initialise output tab
CurrPrev2StepSizeTab.Properties.VariableNames = FinalVarNames; %set variable names for output table

%get var names for the current and prev step size parts of the final table
TabVarNames_Curr = strcat('Curr',{'IVI'}); 
TabVarNames_Curr  = [ResponseVarNames,TabVarNames_Curr]; %add Response as an additional var name to the current vars table    
                       
u_SecNum = unique(DistTab.SectionNum); %get unique section numbers

for i = 1:numel(u_SecNum) %go through each section number
    TempTab = DistTab(DistTab.SectionNum == u_SecNum(i),:);

    if size(TempTab,1) >= 3 %we need at least 3 steps in a section to get a set of current, prev, and prev-to-prev step size for rthat section 
        Curr_TempTab = TempTab(:,2:end); %get currIvi col + all response cols (because response info is pertinent to currIVI)
        %Variable names for Curr_TempTab at this point are [[response vars 0.5 to 10], InterVocIntVec]
        Curr_TempTab = Curr_TempTab(3:end,:); %get rows corresponding to current IVI (so starting from the third row, because the first row would have the corresponding 
        % prev-to-prev IVI)
        Prev_TempTab = TempTab(:,end); %get PrevIvi cols (which is simply the list of IVIs; we will index the IVIs corresponing to the prev and prev-to-prev IVIs from this)
        %Variable names for Prev_TempTab at this point are [InterVocIntVec]
        Prev1_TempTab = Prev_TempTab(2:end-1,:); %get rows corresponding to prev IVI (so starting from the second row and ending at end-1)
        Prev1_TempTab.Properties.VariableNames = {'PrevIVI'};
        Prev2_TempTab = Prev_TempTab(1:end-2,:); %get rows corresponding to prev-to-prev IVI (so starting from the 1st row and ending at end-2)
        Prev2_TempTab.Properties.VariableNames = {'Prev2IVI'};
        Prev_TempTab_Combined = [Prev1_TempTab Prev2_TempTab]; %put prev and prev-to-prev IVI tables together
        
        %recast var names
        Curr_TempTab.Properties.VariableNames = TabVarNames_Curr; %Variable names for Curr_TempTab at this point are [[response vars 0.5 to 10], CurrIVI]
        %Prev_TempTab.Properties.VariableNames = TabVarNames_Prev; %Variable names for Curr_TempTab at this point are [PrevIVI]
    
        ProcessedTab = [Curr_TempTab Prev_TempTab_Combined]; %putb both togther
        %ProcessedTab = ProcessedTab(~isnan(ProcessedTab.Response),:);%remove NA responses
    
        CurrPrev2StepSizeTab = [CurrPrev2StepSizeTab; ProcessedTab]; %stack
    end
end

% % The check below is not going to work because we only use the 5 s response window for this illustrative analyses, but the responsewindow loop below is indexed from i = 1. 
% % I could redo this so that check for the entire response window vector (which would make this work for the case of only having one response window, but I like the check being 
% % more general in case we expand this to more response windows than 5. At any rate, the original previous IVI function (where we only get teh previous IVI) does this check 
% % without any issues, so I am commenting this out for now. 
% %checks: we are going to do the following checks, just to make sure that everything works as intended.
% %1. now, let's check to make sure that NaN response steps ARE included
% for i = 2:numel(ResponseWindow) %because minimum IVI is 0.6 s, so a response window of 0.5 s is not going to have an NA response, so start from response window = 1 s
%     CurrRespCol = CurrPrev2StepSizeTab.(ResponseVarNames{i});
%     if numel(CurrRespCol) == numel(CurrRespCol(~isnan(CurrRespCol)))%if NaN responses and associated steps have been excludeed, then
%         %the number of elements in Response vector before and after removing NaN responses will be the same. So, if this condition is satisfied, we know that NaN responses have already been 
%         %excluded. However, the exception to this is if there are no NaN responses in the table (which could be possible for 5 min sections)
%         DistTab
%         disp('NaN responses and associated steps have already been removed from the table. OR this is a 5 min section')%if, for a response window value, this condition is true, 
%         %display message and DistTab, and break
%         break
%     end
% 
%     %2. Finally, let's make sure that all IVIs less than or equal to response window are associated with NaN responses.
%     ResponseForShortIvis = CurrRespCol(CurrPrev2StepSizeTab.CurrIVI <= ResponseWindow(i)); %get Response values for Ivis <= response window
%     if ~isempty(ResponseForShortIvis(~isnan(ResponseForShortIvis)))
%         error('IVIs less than or equal to response window have not been flagged as associated with NaN response')
%     end 
% end