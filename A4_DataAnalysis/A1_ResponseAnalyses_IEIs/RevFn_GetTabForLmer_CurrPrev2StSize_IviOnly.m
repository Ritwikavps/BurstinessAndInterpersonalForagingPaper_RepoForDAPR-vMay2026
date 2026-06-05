function [CurrPrev2StepSizeTab_Agg] = RevFn_GetTabForLmer_CurrPrev2StSize_IviOnly(ZscoreDir, ResponseWindow_s, SpkrType, OtherType, NAType, StringToRemoveFromFname, MetadataTab)

% Ritwika VPS, Dec 2025
% This is part of additional analyses code being written for the Burstiness paper in response to reviewer comments (however, I am preserving the 'step size' language as 
% opposed to IEI in function names etc for continuity with the rest of the code.

%This script and associated functions will analyse infant and adult step sizes and get current and prev step size info + WR/WOR info, age, infant
%ID, and put it into a single table for further statistical analyses.

%Inputs: - ZscoreDir: structure that has list of all relevant files (output of dir() on the relevant directory)
        %- ResponseWindow_s: the vector of response window times (in seconds) 
        %- SpkrType: the target speaker (eg. CHNSP)
        %- OtherType: the responder (eg. if we are looking at the effect of adult response on infant vocs, then this would be AN)
        %- NAType: the speaker label that triggers an NA response (see ComputeResponseVector.m for details)
        %- StringToRemoveFromFname: the substring to remove from the filename to get the filename root (eg. If the filename is '0009_000302_ZscoredAcousticsTS_LENA.csv'
            % , then the string to remove would be '_ZscoredAcousticsTS_LENA.csv', so we get the filename root '0009_000302'
        %- MetadataTab: the table containing metadata info

%Output: CurrPrevStepSizeTab_Agg: table with all Current and previous step size details for each infant at each age, aggregated across the whole corpus,
            %along with infant ID and infant age info.
      %- ZeroIviMergeDetails: table w the total number of voc merges that have been performed, for each recording, plus relevant infant age and ID details. 

CurrPrev2StepSizeTab_Agg = array2table(zeros(0,numel(ResponseWindow_s) + 6)); %initialise output table
for i = 1:numel(ResponseWindow_s) %go through response window vector and get response variable names for each response window value
    RespVarName{1,i} = strcat('Response_',num2str(ResponseWindow_s(i)));
end
FinalVarNames = [RespVarName,'CurrIVI','PrevIVI','Prev2IVI','InfantID','AgeDays','AgeMonths']; %set variable names

CurrPrev2StepSizeTab_Agg.Properties.VariableNames = FinalVarNames; %set variable names for output table

for i = 1:numel(ZscoreDir) %go through list of files

    ZscoreFnRoot = erase(ZscoreDir(i).name, StringToRemoveFromFname); % get the root of the filename
    ZscoreTab = readtable(ZscoreDir(i).name,'Delimiter',',');
    
    [CurrPrev2StepSizeTab] = RevFn_Get_CurrPrev2StSizeTab_IviOnly(ZscoreTab,SpkrType, OtherType, NAType, ResponseWindow_s);

    %get infant id and age
    NumRows = numel(CurrPrev2StepSizeTab.CurrIVI); %number of rows in table
    InfantID = cell(NumRows,1);
    [InfantID{:}] = deal(MetadataTab.InfantID(contains(MetadataTab.FileNameRoot,ZscoreFnRoot)));
    AgeDays = MetadataTab.InfantAgeDays(contains(MetadataTab.FileNameRoot,ZscoreFnRoot))*ones(NumRows,1);
    AgeMonths = MetadataTab.InfantAgeMonth(contains(MetadataTab.FileNameRoot,ZscoreFnRoot))*ones(NumRows,1);

    CurrPrev2StepSizeTab.InfantID = InfantID;
    CurrPrev2StepSizeTab.AgeDays = AgeDays;
    CurrPrev2StepSizeTab.AgeMonths = AgeMonths;

    CurrPrev2StepSizeTab_Agg = [CurrPrev2StepSizeTab_Agg; CurrPrev2StepSizeTab]; 
end
