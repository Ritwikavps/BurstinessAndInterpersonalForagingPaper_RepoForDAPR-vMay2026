function T_AnnotInOrthoTierButNotAdultUttDirTier_out = GetAnnotInOrthoButNotInUttDir(TierInfoTable,EafFilename,OpTabPlaceHolder)

    %%@author info, JUne 2022; Modified Nov 2023
    
    %function to check whether any annotations that are in the adult orthographic transcription tier are missing from the utternace direction tier or vice-versa
    %In addition, this function also identifies annotations that are in the music and background overlap tiers but missing from the utterance
    %direction tier or vice versa. Thsi was added after the function was originally written, so I haven't bothered changing the function name
    
    %inputs: TierInfoTable: Table with info parsed from eaf file (col nameS: %Clumn names: StartTimeRef, StartTimeLineNum, 
                            %EndTimeRef, EndTimeLineNum, AnnotId, AnnotIdLineNum, Annotation, AnnotationLineNum
                            %TierTypeVec, StartTimeVal, EndTimeVal, EafFnam)
            %T_AnnotInOrthoTierButNotAdultUttDirTier: initialised table with mismatched or incorrect tiers 
                            %that we continue to populate
            %Eaf file name
    %output: T_AnnotInOrthoTierButNotAdultUttDirTier_out populated with mismatched or
            %otherwise incorrect annotations from this run of the function
    
    %first get subtables contaiing only orthographic annotations, adult
    %utterance dir annotation, music, and background overlap tiers
    T_AdultOrthoTranscrip = TierInfoTable(contains(TierInfoTable.TierTypeVec,'Adult Ortho','IgnoreCase',true),:);
    T_AdultUttDirAnnot = TierInfoTable(contains(TierInfoTable.TierTypeVec,'Adult Utterance Dir','IgnoreCase',true),:);
    T_Music = TierInfoTable(contains(TierInfoTable.TierTypeVec,'Music','IgnoreCase',true),:);
    T_BgOlp = TierInfoTable(contains(TierInfoTable.TierTypeVec,'Background Overlap','IgnoreCase',true),:); 
    
    %check if there are repeats in the start and end times for both tables 
    UniqCheck = [abs(numel(T_AdultUttDirAnnot.StartTimeVal)-numel(unique(T_AdultUttDirAnnot.StartTimeVal))) 
        abs(numel(T_AdultUttDirAnnot.EndTimeVal)-numel(unique(T_AdultUttDirAnnot.EndTimeVal)))
        abs(numel(T_AdultOrthoTranscrip.StartTimeVal)-numel(unique(T_AdultOrthoTranscrip.StartTimeVal)))
        abs(numel(T_AdultOrthoTranscrip.EndTimeVal)-numel(unique(T_AdultOrthoTranscrip.EndTimeVal)))
        abs(numel(T_Music.StartTimeVal)-numel(unique(T_Music.StartTimeVal))) 
        abs(numel(T_Music.EndTimeVal)-numel(unique(T_Music.EndTimeVal)))
        abs(numel(T_BgOlp.StartTimeVal)-numel(unique(T_BgOlp.StartTimeVal)))
        abs(numel(T_BgOlp.EndTimeVal)-numel(unique(T_BgOlp.EndTimeVal)))];
    
    
    if sum(UniqCheck) > 0
        fprintf('There are duplicate time values in %s \n',EafFilename) %verified that there are no duplicate time entries
    end
    
    if ~isempty(T_AdultUttDirAnnot) %only proceed if utt dir table not empty
        OpTabPlaceHolder = CheckAnnotsInTier1ButNotTier2(T_AdultUttDirAnnot,T_AdultOrthoTranscrip,OpTabPlaceHolder);
        OpTabPlaceHolder = CheckAnnotsInTier1ButNotTier2(T_AdultUttDirAnnot,T_Music,OpTabPlaceHolder);
        OpTabPlaceHolder = CheckAnnotsInTier1ButNotTier2(T_AdultUttDirAnnot,T_BgOlp,OpTabPlaceHolder);
    end
        
    T_AnnotInOrthoTierButNotAdultUttDirTier_out = OpTabPlaceHolder;
    
    %----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function [OpTab] = CheckAnnotsInTier1ButNotTier2(AdultUttDirTab,Tier2Tab,OpTab)
        if ~isempty(Tier2Tab) %only proceed if tier 2 is not empty
            %now go through tier 2 table start and end times and compare to adult utterance direction start and end time
            for k = 1:numel(Tier2Tab.StartTimeRef)
                if (~ismember(Tier2Tab.StartTimeVal(k),AdultUttDirTab.StartTimeVal)) ...
                        || (~ismember(Tier2Tab.EndTimeVal(k),AdultUttDirTab.EndTimeVal)) %if either start or end time of any Tier2 annotation
                    %is missing in the utterance direction tier, add to the table
                    %keeping track of this
                    OpTab = [OpTab; Tier2Tab(k,:)];
                end 
            end
    
            %go through utterance direction tier and check if there are utterance direction tier annotationns that
            %are not present in the Tier2tab
            for k = 1:numel(AdultUttDirTab.StartTimeRef)
                if (~ismember(AdultUttDirTab.StartTimeVal(k),Tier2Tab.StartTimeVal)) ...
                        || (~ismember(AdultUttDirTab.EndTimeVal(k),Tier2Tab.EndTimeVal)) %if either start or end time of any utterance dir annotation
                    %is missing in Tier2, add to the table
                    %keeping track of this
                    OpTab = [OpTab; AdultUttDirTab(k,:)];
                end 
            end
        end
    end
end

