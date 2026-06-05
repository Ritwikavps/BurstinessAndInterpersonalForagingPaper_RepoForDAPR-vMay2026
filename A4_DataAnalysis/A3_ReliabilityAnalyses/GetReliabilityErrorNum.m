function [NumFA,NumMiss,NumConf,NumConfCHN,NumSpeech_Hum] = GetReliabilityErrorNum(LabelSetIntersectMat,VocLabelSet)

%This function calculates the raw number of frames for false alarms, misses, confusions, as well as the total number of frames the human annotator id's as speech (all of this goes into computing
% the reliability error rates).

%Inputs: 
    %- LabelSetIntersectMat: the confusion matrix for Human annotator and LENA (hum indexed by rows, LENA indexed by col).
    %- VocLabelSet: the set of labels used to compute the confusion matrix, in the order used in the confusion matrix calculation.
%Outputs:
    %- NumFA, NumMiss: Number of false alarms and misses
    %- NumConf: Number of confusions with CHNSP and CHNNSP trated as separate labels
    %- NumConfCHN: Number of confusions with CHNSP and CHNNSP treated as a single CHN label
    %- NumSpeech_Hum: Number of frames human annotator identified as speech.


%"The error rates are calculated with the following formulas at the level of each clip, where:
    %- FA (false alarm) is the number of frames during which there is no talk according to the human annotator but during which LENA® found some talk; 
    %- M (miss) is the number of frames during which there is talk according to the human annotator but during which LENA® found no talk; 
    %- C (confusion) is the number of frames correctly classified by LENA® as containing talk, but whose voice type has not been correctly identified (when the LENA® model 
        % recognizes female adult speech where there is male adult speech for instance)
    %- T is the total number of frames that contain talk according to the human annotation
%Then, False alarm rate = FA/T; miss rate = M/T; confusion rate = C/T; Id error rate = (FA + M + C)/T

%Firts, check that the VocLabelSet si in the expected order. This is because this affects how the confusion matrix is ordered.
if ~isequal(VocLabelSet,{'CHNSP','CHNNSP','AN','NA-NotLab'})
    error('VocLabelSet is not in the expected order')
end

%Now, given the expected VocLabelSet order (see above), the number of false alarms is the number of frames that human listener (the true annotator) labels as NA-NotLab, but LENA (the test 
% annotator) labels as speech. Thus, this would simply be the sum of the last row of the LabelSetIntersectMat (corresponding, collectively, to the frames the human annotator labelled as 
% NA-NotLab, ie. not speech) except the last element (the 4th element) corresponding to number of frames LENA and human annotator agree as NA-NotLab.
%The number of misses is the number of frames that human listener (the true annotator) labels as speech, but LENA (the test annotator) labels as not speech. Thus, this would simply be the sum
% of the last column of the LabelSetIntersectMat (corresponding, collectively, to the frames LENA labelled as NA_NotLab or not-speech) except the last element (the 4th element) corresponding 
% to number of frames LENA and human annotator agree as NA-NotLab.
% Finally, the number of confusions would be when LENA and human annotator agreed on speech but disagreed on the specific label. The 3x3 sq matrix (exluding the 4th row and column in the
% confusion matrix) corresponds to all the cases where LENA and human annoator agreed on speech, while the diagonal of this matrix is the number of frames both annotators agreed on the specific
% label. So, the number of confusions is the matrix sum of this 3x3 sq matrix minus the sum of the diagonal. 
% However, if we are interested in the number of confusions without making the distinction betwenn child speech related (CHNSP) and non-speech related (CHNNSP), and instead, treating CHN as a
% single label, we need to trest the 2x2 matrix (corresponding to LabelSetIntersectMat(1:2,1:2) as a single element, since this corresponds to the CHNSP and CHNNSP labels for both annotators.
% Then, this case of confusions is given by the sum of the 3x3 sq matrix minus the sum of the 2x2 matrix minus the last diagonal element of the 3x3 matrix.
NumFA = sum(LabelSetIntersectMat(end,1:3));
NumMiss = sum(LabelSetIntersectMat(1:3,end));
SpeechBlock = LabelSetIntersectMat(1:3,1:3); %Get the speech only block
ChnBlock = LabelSetIntersectMat(1:2,1:2); %Get the Chn-only block
NumConf = sum(SpeechBlock(:))-sum(diag(SpeechBlock));
NumConfCHN = sum(SpeechBlock(:))-sum(ChnBlock(:))-SpeechBlock(end,end);

%For the total number of frames the human annotator (true annotation) labelled as speech,. we need the sum of the first three rows of LabelSetIntersectMat.
NumSpeech_Hum = sum(sum(LabelSetIntersectMat(1:3,:)));

