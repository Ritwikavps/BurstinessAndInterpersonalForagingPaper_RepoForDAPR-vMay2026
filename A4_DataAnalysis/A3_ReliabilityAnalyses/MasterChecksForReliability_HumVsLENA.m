function [] = MasterChecksForReliability_HumVsLENA(ReliabilityNumsTab_Agg, ConfusionStruct, VocLabelSet)

%This function carries out ALL the checks after we get the reliability error nums and precison and recall nums (per Cristia et al).

%CHECK 1 ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
% Check that section vs file rows for total aggregate table are same. 

%first, get the types of human listener files (all adult or child-directed adult ONLY) as well as the strings correspodning to section or file levelk outputs.
u_HumAdType = unique(ReliabilityNumsTab_Agg.AN_Type);
u_SecOrFileLvl = unique(ReliabilityNumsTab_Agg.SecOrFileLvl);

%get the number of columns for table for check 3. We remove the specified columns because we don't need these for check 3 (for details about check 3, see later in this function).
NumColsForChk3 = width(removevars(ReliabilityNumsTab_Agg,{'Fname','AgeMonths','SecOrFileLvl','CohensKappa','PercentAgreement'})); 
TabForChk3 = array2table(zeros(0,NumColsForChk3)); %initialiose table to store results for check 3
%get variable names for the table for check 3.
TabForChk3.Properties.VariableNames = setdiff(ReliabilityNumsTab_Agg.Properties.VariableNames,{'Fname','AgeMonths','SecOrFileLvl','CohensKappa','PercentAgreement'});
for i = 1:numel(u_HumAdType) %go thropugh adult voc category ('All' or 'ChildDir')
    SubTab = ReliabilityNumsTab_Agg(contains(ReliabilityNumsTab_Agg.AN_Type,u_HumAdType{i}),:); %subset for the adult voc category type
    for j = 1:numel(u_SecOrFileLvl)
        SecOrFileTabSum{j} = sum(removevars(SubTab(contains(SubTab.SecOrFileLvl,u_SecOrFileLvl{j}),:),{'Fname','AgeMonths','SecOrFileLvl','AN_Type','CohensKappa','PercentAgreement'}));
        %here, we subset the table for the SecOrFileLvl string type, remove unnecessary columns, and get the sum.
    end

    if ~isequal(SecOrFileTabSum{1},SecOrFileTabSum{2}) %check if both rows are equal
        error('The sum of the various frame numbers (eg. number of misses, number of frames labelled CHNSP by LENA, etc) computed do not match for section and file level computations')
    end

    SecOrFileTabSum{1}.AN_Type = u_HumAdType(i); %add the adult voc type class back for CHECK 3
    TabForChk3 = [TabForChk3; SecOrFileTabSum{1}]; % add the row to the table
end
% ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ 

%CHECK 2 ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
% Check rows and cols of the aggregate precision and recall matrices sum to one as applies:

for i = 1:numel(ConfusionStruct) %go through structure. Note that the ith structure elements correspond to the i-th adult voc type category (ie, all adult vocs or child-directed adult
    % vocs ONLY). The cells LabelSetIntersectNums_Cell, NumDenom_Recall_ColVec_Cell, and NumDenom_Prec_RowVec_Cell all have N elemenets, where each element is the individual numerator 
    % and denominator matrices to compute the precision and recall matrices for a given file, and N = the total number of files we do reliability on.
    %Thus, summing these cell arrays (individually) gives the total number of frames for the numerator and denominator matrices to compute precision and recall across the whole dataset.
    %To do this, concatenate the cell array elements along the third dimension to get the total number of frames across the dataset
    ConfusionStruct(i).TotNumIntersect = sum(cat(3,ConfusionStruct(i).LabelSetIntersectNums_Cell{:}),3);  
    ConfusionStruct(i).TotDenomRecall_ColVec = sum(cat(3,ConfusionStruct(i).NumDenom_Recall_ColVec_Cell{:}),3);
    ConfusionStruct(i).TotDenomPrecision_RowVec = sum(cat(3,ConfusionStruct(i).NumDenom_Prec_RowVec_Cell{:}),3);

    %convert the recall denominator column vector and the precision denominator row vector to the same dimensions as TotNumIntersect.
    TotDenomRecall = ConfusionStruct(i).TotDenomRecall_ColVec.*ones(1,numel(VocLabelSet));
    TotDenomPrecision = ConfusionStruct(i).TotDenomPrecision_RowVec.*ones(numel(VocLabelSet),1);
    TotRecall = (ConfusionStruct(i).TotNumIntersect)./TotDenomRecall;
    TotPrec = (ConfusionStruct(i).TotNumIntersect)./TotDenomPrecision;

    PrecColSum = sum(TotPrec,1); %sum of each col (sum is along the row dimension, ergo, dim = 1)
    RecallRowSum = sum(TotRecall,2); %sum of each row (sum is along the col dimension, ergo, dim = 2)  

    if  all(PrecColSum ~= 1) || all(RecallRowSum ~= 1) %check that all elements of the sum of rows or cols, as applies, are equal to 1.
        warning('Rows (for recall matrix) or cols (for precision matrix) do not sum to 1')
    end
end
% ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ 

%CHECK 3 ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
% Check that only the number of AN and NA-NotLab labels as LENA and human annotator agree on changs between the two types of adult voc cases (all adult vocs vs ONLY child directed) for 
% human listener labels. Further, the total number of adult frames should decrease while the total number of NA-NotLan frames should increase for teh case where only child-directed
% adult vocs are considered.
TabVarNames = TabForChk3.Properties.VariableNames; %get table variable names 

%pick out the AN_Type var name as well as the variable names that are relevant:
ReqVarNames_CHN = TabVarNames(contains(TabVarNames,'NumFrame') & contains(TabVarNames,'CHN') & ~contains(TabVarNames,'LENA')); %any CHN frame numbers for Human listener label as well 
% as agreement between LENA and human listener label.
ReqVarNames_AN = TabVarNames(contains(TabVarNames,'NumFrame') & contains(TabVarNames,'AN') & ~contains(TabVarNames,'LENA')); %any AN frame numbers for Human listener label as well 
% as agreement between LENA and human listener label.
ReqVarNames_NA = TabVarNames(contains(TabVarNames,'NumFrame') & contains(TabVarNames,'NA-NotLab') & ~contains(TabVarNames,'LENA')); %any NA-NotLab frame numbers for Human listener label 
% as well as agreement between LENA and human listener label.

TabForChk3 = removevars(sortrows(TabForChk3,'AN_Type'),'AN_Type'); %this ensures that the table is sorted by the AN_Type column, with numbers from the case of All adult vocs first

TabForChk3_AN = TabForChk3(:, ReqVarNames_AN); %pick out numbers for adult labels
if ~all(table2array(TabForChk3_AN(1,:) > TabForChk3_AN(2,:)) == 1) %check if all frame numbers for adult labels are greater for the 'All adult vocs' case (as it should be)
    error('Not all adult frame numbers for all adult vocs are greater than child-directed adult voc ONLY (see details in the user-defined function that generated this error)')
end

TabForChk3_CHN = TabForChk3(:, ReqVarNames_CHN); %pick out number for infant labels
if ~all(table2array(TabForChk3_CHN(1,:) == TabForChk3_CHN(2,:)) == 1) %check if all frame numbers for infant labels are equal for the 'All adult vocs' and 'infant-directed adult ONLY'
% cases (as it should be)
    error('Not all infant frame numbers for all adult vocs are greater than child-directed adult voc ONLY (see details in the user-defined function that generated this error)')
end

TabForChk3_NA = TabForChk3(:, ReqVarNames_NA); %pick out number for NA-NotLab labels
if ~all(table2array(TabForChk3_NA(1,:) < TabForChk3_NA(2,:)) == 1) %check if all frame numbers for NA-NotLab labels are less for the 'All adult vocs' than 'infant-directed adult ONLY'
% cases (as it should be)
    error('Not all NA frame numbers for all adult vocs are less than child-directed adult voc ONLY (see details in the user-defined function that generated this error)')
end






