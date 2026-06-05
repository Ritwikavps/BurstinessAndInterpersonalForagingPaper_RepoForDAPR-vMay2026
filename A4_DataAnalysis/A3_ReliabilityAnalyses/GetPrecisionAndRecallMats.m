function [LabelSetIntersectNums,NumDenom_Precision_RowVec,NumDenom_Recall_ColVec,CohensKappa,PercentAgreement] = GetPrecisionAndRecallMats(Truefile, Testfile, VocLabelSet)

%This function computes the precision and recall matrices (or at least, the numerator and denominators for them, for each file. We will take all of these, sum them, and then divide the
% numerator by the denominator to compute the overall precision and recall matrices).
% In Addition, this function also computes the cohneskappa and cimple percent agreement

%Precision is a measure of LENA's precision, i.e, for each category, it is the number of frames LENA and human annotator agree on, divided by the total number of frames LENA labelled as that
    % category. That is, it is ratio of how often LENA was correct for a category (eg. CHNSP) and how often LENA overall labelled that category. Put more simply, it is a measure of how often
    % was LENA correct.
    %In the confusion matrix for precision, the (i,j)th element--where human labels are indexed by  i (the row index; true values) and the LENA labels are indexed by j (the col index; test 
        % values)-- is given by the number of frames labelled as category j by LENA that are labelled as category i by the human listener, divided by the total number of frames that 
        % are labelled j by LENA. That is, the (i,j)th element is the proportion of frames that are labelled j by LENA that correspond to category i as labelled by the human listener,
        % wrt the total number of frames labelled j by LENA.
        % Note that every column sums to 1. 
%Recall is a measure of how much of the 'correct' tag (as labelled by the human annotator) did LENA accurately identitfy (or recalled/recovered). So, this is the number of frames LENA and 
    % human annotator agree on for a category divided by the number of frames the human annotator id'd as that category.
    %In the confusion matrix for recall, the (i,j)th element--where human labels are indexed by  i (the row index; true values) and the LENA labels are indexed by j (the col index; test 
        % values)-- is given by the number of frames labelled as category j by LENA that are labelled as category i by the human listener, divided by the total number of frames that 
        % are labelled i by the human listener. That is, the (i,j)th element is the proportion of frames that are labelled j by LENA that correspond to category i as labelled by the human 
        % listener wrt the total number of frames labelled i by Hum. Note that every row sums to 1. 
    % Also note that for precision and recall, the numerator remains the same, and it is the denominator that changes.

%The inputs are:
    %1. Truefile: the True File, which we assume to be the ground truth (or as close to ground truth as possible; this would be the human listener labelled file, usually).
    %2. Testfile: the file we test against the grounf truth file, usually the LENA labelled file.
    %3. VocLabelSet: the set of unqiue vocal labels we are using to compute reliability metrics. We specify these because this specification allows us to do reliabilty by considering 
        % infant vocs as speech related and non-speech related (CHNSP and CHNNSP) or as a single label type (CHN).

 %The outputs are matrices for:
    %1. LabelSetIntersectNums: the numerator for the precision and recall matrices, with the number of intersections for each label set category, in the form of a confusion matrix. This means that
        % (as described above) this output array has its (i,j)th element as the number of frames labelled as category j by LENA (test labeller) that are labelled as category i by the human 
        % listener (true labeller)
        % are labelled j by LENA.
    %2. NumDenom_Precision_RowVec: The denominator row vector for precison
    %3. NumDenom_Recall_ColVec: the denominator column vector for recall

LabelSetIntersectNums = confusionmat(Truefile.speaker,Testfile.speaker,'Order',VocLabelSet); %'Order' specifies that the order of labels should be as specified in VocLabelSet. So, the ith label
%in VocalLabelSet will correspond to the ith row (for the True file) and the ith column (for the Test file).
NumDenom_Precision_RowVec = sum(LabelSetIntersectNums,1); %The sum along the row dimension, resulting in a row vector, gives the number of labels of each category by 
NumDenom_Recall_ColVec = sum(LabelSetIntersectNums,2);

%check that rows and columns of recall and precision matrices sum to 1, respectively. To do this, we need to stack the vectors NumDenom_Precision_RowVec and NumDenom_Recall_ColVec into
% arrays the same size as Num_Intersect (see below).
PrecColSum = sum(LabelSetIntersectNums./(NumDenom_Precision_RowVec.*ones(numel(VocLabelSet),1)),1); %sum of each col (sum is along the row dimension, ergo, dim = 1). Here, since the denominator
% is a row vector, we do an element-by-element multiplication with a column vector of ones, so we get a matrix where the denominator row vector is stacked numel(VocaLabelSet) times. A
% similar procedure is done below to get the denominator matric to comput the recall matrix.
RecallRowSum = sum(LabelSetIntersectNums./(NumDenom_Recall_ColVec.*ones(1,numel(VocLabelSet))),2); %sum of each row (sum is along the col dimension, ergo, dim = 2)

%note that sometimes, at the section or file level, there can be NaNs, because sometimes there might be no LENA or human annotator labels of a certaion category. Eg. for a 5 min section, 
% there may not be any frame that's been id'd by the human annotator as CHNNSP. In this case, the recall row for the CHNNSP category will be NaN. Below, I account for that, by first removing
% NaNs, and then checking that all remaining elements of the relevant sum are equal to 1. So, the all(x ~= 1) checks if there are array elements that aren't 1. The filtering for NaN
% works here because if LENA says there are 0 Chnsp labels, then the corresponding precision vector will be 0, but all the elements in teh intersection matrix for the LENA Chnsp labels
% will also be 0 because there will be no frames that hum agrees is any label that LENA says is Chnsp.
if  all(PrecColSum(~isnan(PrecColSum)) ~= 1) || all(RecallRowSum(~isnan(RecallRowSum)) ~= 1) %check that all elements of the sum of rows or cols, as applies, excluding NaNs, as 
    %explained above, are equal to 1
    warning('Rows (for recall matrix) or cols (for precision matrix) do not sum to 1 for %s',Testfile.FnameUnmerged{1})
end

% A quick note: there should be as many cols as there are test (LENA) label categories, and as many rows as there are true (human) label categories. So, in cases where the true and test label
% sets are not exatly one-to-one (as is the case in the Cristia et al paper; note that this is not how this code is set up, rather, this code is set up for the true and test label sets being
% the same), so for the precision matrix, the sum of each column should be 1, and the sum of the sum of columns (that is, teh matrix sum), should be equal to the number of test labels.
% SImilarly, for the recall matrix, the matrix sum should be equal to the number of true labels.

%Finally, let's compute the cohen's kappa and simple percent agreement. 
% Now, LabelSetIntersectNums is the confusion matrix. NumDenom_Precision_RowVec and NumDenom_Recall_ColVec, respectively, give the number of frames
% labelled as (in order) {'CHNSP','CHNNSP','AN','NA-NotLab'}, by LENA and human annotator. Thus, these vectors divided by the total number of frames gives us the expected probability of 
% each category by that rater. That is, [NumDenom_Precision_RowVec/(tot number of frames = sum(LabelSetIntersectNums))] will give the expected probability of LENA randomly labelling a frame
% as (in order) {'CHNSP','CHNNSP','AN','NA-NotLab'}. And similarly for the human listener.
TotNumFrames = sum(LabelSetIntersectNums(:));
LENA_Probability = NumDenom_Precision_RowVec/TotNumFrames; 
Hum_Probability = NumDenom_Recall_ColVec/TotNumFrames;
ExpectedAgreement = sum(LENA_Probability.*Hum_Probability'); %This is the expected probability that human annotator and LENA agree on a label by chance (based on the observed probabilities
%for each label for LENA and human annotator)
ObsAgreement = sum(diag(LabelSetIntersectNums))/TotNumFrames; %This is the percent agreement
CohensKappa = (ObsAgreement-ExpectedAgreement)/(1-ExpectedAgreement);
PercentAgreement = ObsAgreement;
