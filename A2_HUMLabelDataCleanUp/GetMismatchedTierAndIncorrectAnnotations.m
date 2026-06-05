function [T_TierMismatchOrIncorrectAnnot_Output] = GetMismatchedTierAndIncorrectAnnotations(TierInfoTable,T_TierMismatchOrIncorrectAnnot)

%%@author info, JUne 2022

%function to check whether any annotations are in mismatched tiers and/or if there are non-sensical or missing annotations

%inputs: TierInfoTable: Table with info parsed from eaf file (col nameS: %Clumn names: StartTimeRef, StartTimeLineNum, 
                        %EndTimeRef, EndTimeLineNum, AnnotId, AnnotIdLineNum, Annotation, AnnotationLineNum
                        %TierTypeVec, StartTimeVal, EndTimeVal, EafFnam)
        %T_TierMismatchOrIncorrectAnnot: initialised table with mismatched or incorrect tiers 
                        %that we continue to populate
%output: T_TierMismatchOrIncorrectAnnot populated with mismatched or
        %otherwise incorrect annotations from this run of the function
        
for j = 1:numel(TierInfoTable.StartTimeRef)
    if contains(TierInfoTable.TierTypeVec{j},'Infant Voc Type') %if infant voc type tier
        if sum(strcmpi(strtrim(TierInfoTable.Annotation{j}),{'X','R','C','L'})) ~= 1 %if, after eliminating white space, the infant annotation 
            %is not one of these types; we eliminate white space from the comparison because we can go in and edit white space
            %and tab characters we use contains instead of strcmpi becuase white space and
            %random non-text characters are things we can go in and edit ourselves
            T_TierMismatchOrIncorrectAnnot = [T_TierMismatchOrIncorrectAnnot; TierInfoTable(j,:)];
        end
    elseif contains(TierInfoTable.TierTypeVec{j},'Adult Utterance Dir') %if adult utterance tier
        if sum(strcmpi(strtrim(TierInfoTable.Annotation{j}),{'T','U','N'})) ~= 1 %if, after eliminating white space, the infant annotation 
        %is not one of these types
            T_TierMismatchOrIncorrectAnnot = [T_TierMismatchOrIncorrectAnnot; TierInfoTable(j,:)];
        end
    elseif contains(TierInfoTable.TierTypeVec{j},'Adult Ortho') %if orthographic transcription tier
        if sum(strcmpi(strtrim(TierInfoTable.Annotation{j}),{'T','U','N','X','L','R','C'})) ~= 0
            T_TierMismatchOrIncorrectAnnot = [T_TierMismatchOrIncorrectAnnot; TierInfoTable(j,:)];
        end
    end
end

T_TierMismatchOrIncorrectAnnot_Output = T_TierMismatchOrIncorrectAnnot;