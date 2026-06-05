function [] = CheckReliabilityNumFrames_MatlabVsUser(Hfile, Lfile, VocLabelSet,...
                                                ConfusionMat_Matlab, NumDenom_Prec_Rowvec_Matlab, NumDenom_Recall_Colvec_Matlab, ...
                                                NumFA_Matlab,NumMiss_Matlab,NumConf_Matlab,NumConfCHN_Matlab)
%This function manually computes number of false alarms, misses, etc, to check against the numbers computed using ConfusionMat (as a sanity check). Inputs are the human and LENA files,
% the set of speaker labels (VocLabelSet); the confusion matric, precison vector, and recall vector computed using MATLAB's confusionmat(); number of FAs, misses, and confusions (for
% the case when CHN is treated as a single type and for the case when CHNSP and CHNNSP are treated as different types).

[Num_Intersect_User, NumDenom_Prec_Rowvec_User, NumDenom_Recall_Colvec_User] = GetPrecisionAndRecallMats_ToCheck(Hfile,Lfile,VocLabelSet);

%check that the confusion matrix computed by MATLAB and the number of intersection (Num_Intersect) as computed here are the same (and similarly for the denominators for the precison
% and recall mats.                                                                                                                                                  
if (~isequal(ConfusionMat_Matlab,Num_Intersect_User)) || (~isequal(NumDenom_Recall_Colvec_User,NumDenom_Recall_Colvec_Matlab)) ...
        || (~isequal(NumDenom_Prec_Rowvec_User,NumDenom_Prec_Rowvec_Matlab))                                                                                                                                     
    error('Numerator or denominator(s) for precison and recall matrices as computed by Matlab and using user-defined function do not match for %s',Lfile.FnameUnmerged{1})                               
end 

[Num_FA_User,Num_Miss_User,Num_Confusion_CHN_User,Num_Confusion_User] = GetErrorRatesNumFrames_ToCheck(Hfile,Lfile);
if (Num_FA_User ~= NumFA_Matlab) || (Num_Miss_User ~= NumMiss_Matlab) ||  (Num_Confusion_CHN_User ~= NumConfCHN_Matlab) || (Num_Confusion_User ~= NumConf_Matlab)
    error('At least one of out of the number of false alarms, number of misses, and number of confusions do not match between computations using built-in MATLAB vs user-defined function(s)')
end

% ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
%functions to compute error numbers and precision and recall matrices using user-defined functions (as opposed to using MATLAB's confusionmat). This is only to check that everything
% works as intended. 
% ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ 

    function [Num_Intersect, NumDenom_Prec_Rowvec, NumDenom_Recall_Colvec] = GetPrecisionAndRecallMats_ToCheck(Hfile,Lfile,VocLabelSet)
        % This function computes the precision and recall matrices explicitly (without using confusionmat). This is just a sanity check because I am an overly cautious person, and 
        % like to have ALL the checks. Note that I implement this for a randomly chosen sample so that we don't spend too much time repeating analyses.
    
        L_Labels = VocLabelSet; H_Labels = VocLabelSet; % get the types of labels to index confusion matrices                                                                                      
        L_spkrcodes = GetSpkrCodesForSpkrLabels(Lfile.speaker,L_Labels); H_spkrcodes = GetSpkrCodesForSpkrLabels(Hfile.speaker,H_Labels); %Convert speaker labels to numbered speaker codes  
        IndVec = 1:numel(L_spkrcodes); %get vector of indices (to do logical indexing)                                                                                                         
                                                                                                                                                                                               
        for i_row = 1:numel(H_Labels) %go through row and column indices                                                                                                                       
            for j_col = 1:numel(L_Labels)                                                                                                                                                      
                L_inds = IndVec(L_spkrcodes == j_col); H_inds = IndVec(H_spkrcodes == i_row); %get indices corresponding to the required human and LENA label category.                        
                Num_Intersect(i_row,j_col) = numel(intersect(L_inds,H_inds)); %find the number of intersections of the i_row-th human label category and the j_col-th LENA label category      
                NumDenom_Prec_Rowvec(1,j_col) = numel(L_inds); %get the number of LENA labels that have been id'd by LENA as that category (for the precision denominator)                            
            end
            NumDenom_Recall_Colvec(i_row,1) = numel(H_inds); %get the number of human labels that have been id'd by human annotator as that category (for the recall denominator)                                                                                                                                                                               
        end 
    end

% ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function [Num_FA,Num_Miss,Num_Confusion_CHN,Num_Confusion] = GetErrorRatesNumFrames_ToCheck(Hfile,Lfile)
        %This function computes number of false alarms, misses, and confusion
        
        %- FA (false alarm) is the number of frames during which there is no talk according to the human annotator but during which LENA® found some talk; 
        %- M (miss) is the number of frames during which there is talk according to the human annotator but during which LENA® found no talk; 
        %- C (confusion) is the number of frames correctly classified by LENA® as containing talk, but whose voice type has not been correctly identified 
        
        H_spkr = Hfile.speaker; L_spkr = Lfile.speaker; %get speaker label vectors 
        if numel(H_spkr) ~= numel(L_spkr) %check that human and LENA 5 min speaker label vectors have the same length
            warning('Human and LENA speaker labels have different lengths: %s',Hfile.FnameUnmerged{1})
        end
        if ~isequal(Hfile.start,Lfile.start) %check that human and LENA start times are the same (and in the same order, so we aren't comparing between different sections)
            warning('Human and LENA start times are different: %s',Hfile.FnameUnmerged{1})
        end
        IndVec = 1:numel(H_spkr); %get vector of indices for the speaker labels
        
        %get logical for when human listener and LENA says no speech and when something is labelled as speech
        H_nospeech_Ind = IndVec(contains(H_spkr,'NA-NotLab')); H_speech_Ind =  IndVec(~contains(H_spkr,'NA-NotLab'));
        L_nospeech_Ind = IndVec(contains(L_spkr,'NA-NotLab')); L_speech_Ind = IndVec(~contains(L_spkr,'NA-NotLab')); 
        
        Num_FA = numel(intersect(H_nospeech_Ind,L_speech_Ind)); %compute number of false alarms
        Num_Miss = numel(intersect(H_speech_Ind,L_nospeech_Ind)); %compute number of misses
        
        %compute number of confusions
        LandH_speechInd = intersect(L_speech_Ind,H_speech_Ind); %when both agree is speech
        L_speech_spkr = L_spkr(LandH_speechInd); %get speech labels ONLY for both labelling types
        H_speech_spkr = H_spkr(LandH_speechInd);
        if sum(contains(unique(L_speech_spkr),'NA-NotLab')) + sum(contains(unique(H_speech_spkr),'NA-NotLab')) ~= 0 %check if the vector(s) with ONLY speech labels contains 
            % 'NA-NotLab' labels
            warning('Vector with ONLY speech labels contains NA-NotLab label: %s',Hfile.FnameUnmerged{1})
        end
        
        Num_Confusion = GetNumConfusion({'AN','CHNNSP','CHNSP'},L_speech_spkr,H_speech_spkr); %get number of confusions for when CHNNSP and CHNSP are considered as differet categories (i.e., 
        %mislabelling between CHNSP and CHNNSP is counted as confusion)
        Num_Confusion_CHN = GetNumConfusion({'AN','CHN'},L_speech_spkr,H_speech_spkr); %get number of confusions when CHN is a single category encom[passing CHNSP and CHNNSP
    end

% ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function Num_Confusion = GetNumConfusion(VocLabels,L_speech_spkr,H_speech_spkr)
        %This function computes the number of instances of confusion for different sets of speaker labels. Here, the input VocLabels is the set of speaker labels that we use for 
        % estimating confusions. That is, if the label set is {CHNSP, CHNNSP, AN}, then we look for confusions where CHNSP as labelled by the human listener is mis-labelled as CHNNSP or AN; 
        % AN as labelled by human listener is mislabelled as CHNSP or CHNNSP; or CHNNSP as labelled by the human listener is mislabelled as CHNSP or AN. L_speech_spkr and H_speech_spkr 
        % are the set of labels per LENA and human annotator where both agree that there is speech (but the labels may not be the same, ergo the need for teh confusion rate). 
        
        %get speaker codes for human and lena speaker labels, where we are only considering labels where LENA and human annotator agree to be speech
        L_spkrcodes = GetSpkrCodesForSpkrLabels(L_speech_spkr,VocLabels); H_spkrcodes = GetSpkrCodesForSpkrLabels(H_speech_spkr,VocLabels);
        Num_Confusion = numel(L_spkrcodes(L_spkrcodes ~= H_spkrcodes)); %get number of confusions
    end

% ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function SpkrCodes = GetSpkrCodesForSpkrLabels(SpkrVec,LabelSet)
        % This function assigns numerical speaker codes to speaker labels. The inputs are the vector containing the speaker labels (SpkrVec), and the vector containing the set of unqiue 
        % speaker labels (LabelSet).
        
        SpkrCodes = zeros(size(SpkrVec)); %initailise vector to store numbered speaker codes
        for i = 1:numel(LabelSet) % go through set of unique speaker labels and assign speaker codes: numerical value i corresponding to ith unique speaker label
            SpkrCodes(contains(SpkrVec,LabelSet{i})) = i;
        end
    end
% ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
end