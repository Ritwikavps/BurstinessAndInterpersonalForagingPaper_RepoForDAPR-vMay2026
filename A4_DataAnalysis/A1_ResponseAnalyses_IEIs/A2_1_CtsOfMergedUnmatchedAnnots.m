clear; clc

%@author info; June 2024
%This script identifies cases (for the human listener labelled data ONLY) where the annotations for vocs that were merged due to an intervening 0 IVI do not matcg. For eg, if two Adult 
% vocs are merged into one but the annotations for the unmerged ones are T and U (instead of being T and T, or U and U). Another example would be two Infant vocs merged but the 
% annotations for the unmerged vocs are X and C (instead of being X and X, or C and C). This doesn't pose an issue for adult vocs, because in the case where we do not consider 
% directedness, and use all adult vocs in our analyses, this would just merged adult vocs wiuth different annotations but sepoarated by 0 IVI into one voc. When we only consider 
% child-directed adult vocs in our analyses, we first select all adult vocs annotated T, and then only merge these.
% However, for infant vocs, there is an argument for keeping vocs with different annotations separate, since these, even when separated by a 0 IVI, are technically distinct vocs. Note,
% however, that we separate CHNSP (annotations X and C) and CHNNSP (annotations R and L) vocs, so two vocs won't be merged if one is CHNSP and the other is CHNNSP. This script is 
% intended to provide a sense of how many such merges exist, for both adult and infant vocs, so we can get a sense of the proportion of vocs affected by this concern and whether we need
% to build in any checks and balances for this.
% As it turns out, there are only 2 such infant merges, where X and C types are merged together, and as such, there doesn't seem to be a need to account for this, especially since none
% of our analyses (currently) rely on the sub-categories (at the annotation level) of CHNSP and CHNNSP, or of Adult vocs. In addition, the rationale for merging vocs with 0 IVIs apply
% here, since the goal was to remove the 0 Ivi cases, to fix the 'skew'/discontinuity in the data due to the presence of 0 Ivis otherwise. Also note that this is only a concern for the 
% human-listener labelled data, since this fine-grained-level of annotations is only availble for the human-listener labelled data. 

%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLEASE CHANGE PATHS AND STRINGS IN FUNCTION CALL APPROPRIATELY
BasePath = '~/BaseDataPath/Data/HUMLabelData/A2_HUMLabelData_PostCleanUp/';
MergedHpath = strcat(BasePath,'A9_NoAcoustics_0IviMerged_Hum/'); %Path to human-listener data, with 0 Ivis merged, and all adult vocs included
MergedHpath_ChildDirANOnly = strcat(BasePath,'A11_NoAcoustics_0IviMerged_Hum_ChildDirANOnly'); %Path to human-listener data, 0 Ivis merged, and only infant-directed adult vocs included
UnmergedHpath = strcat(BasePath,'A7_HlabelTS_Zscored/'); %Path to human-listener data before 0 Ivi Merging

%Get list of files
cd(MergedHpath); MergedHfiles = dir('*NoAcoustics_0IviMerged_Hum.csv');
cd(MergedHpath_ChildDirANOnly); MergedHfiles_ChildDirANOnly = dir('*NoAcoustics_0IviMerged_ChildDirANOnly_Hum.csv');
cd(UnmergedHpath); UnmergedHfiles = dir('*ZscoredAcousticsTS_Hum.csv');
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

%Get counts of merges
[AnVocMergeCtr_AllAN, ChnspVocMergeCtr_AllAN, ChnnspVocMergeCtr_AllAN] = GetMixedAnnotMergesSummary(MergedHfiles,UnmergedHfiles,'All',{''});
[AnVocMergeCtr_ChnDirAN, ChnspVocMergeCtr_ChnDirAN, ChnnspVocMergeCtr_ChnDirAN] = GetMixedAnnotMergesSummary(MergedHfiles_ChildDirANOnly,UnmergedHfiles,'ChnDir',{'U','N'});

AN_VocClass = {'all','only child-directed'}; SpkrType = {'adult','infant sp-related','infat non-sp related'};  %adult voc class (all or child-directed only), and speaker type
%Make array to pass to fprintf (output text)
Sprintf_NumMat = [AnVocMergeCtr_AllAN, ChnspVocMergeCtr_AllAN, ChnnspVocMergeCtr_AllAN; %all AN
                  AnVocMergeCtr_ChnDirAN, ChnspVocMergeCtr_ChnDirAN, ChnnspVocMergeCtr_ChnDirAN]; %Chn-directed AN only
for i = 1:numel(SpkrType) %loop for output text
    for j = 1:numel(AN_VocClass)
        fprintf('The total # of %s voc mergers done where annotations are different when %s adult vocs are considered is %i \n',SpkrType{i},AN_VocClass{j},Sprintf_NumMat(j,i));
    end
end

%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
% This function takes in list of files after 0 s IVIs have been merged (for same voc type) and list of unmerged files, along with a string specifying whether all or only child directed
% adult vocs are included, and the corresponding set of adult annotation labels, and outputs the number of times a voc in the merged file is the result of merging 2 or more
% vocs in the unmerged file where the unmerged vocs have more than one annotation label. Eg. if the set of unmerged vocs have labels C and X and they result in a single merged voc.
% The output numbers are separate for such merges for adult vocs, CHNSP vocs, and CHNNSP vocs.
function [AnVocMergeCtr, ChnspVocMergeCtr, ChnnspVocMergeCtr] = GetMixedAnnotMergesSummary(MergedHfiles,UnmergedHfiles,AnType,AN_AnnotListToExclude)

    AnVocMergeCtr = 0; ChnspVocMergeCtr = 0; ChnnspVocMergeCtr = 0; %Initialise counter variables

    for i = 1:numel(MergedHfiles) %go through list of files
        MergedTab = readtable(MergedHfiles(i).name); UnmergedTab = readtable(UnmergedHfiles(i).name);  %read in table with 0 Ivi merges and table pre-merge
        UnmergedTab = UnmergedTab(:,1:7); %because the unmerged tab has acoustics as well, so gotta remove those columns
        
        if ~strcmp(AnType,'All') %if we aren't considering all adult voc types
            UnmergedTab = UnmergedTab(~contains(UnmergedTab.Annotation,AN_AnnotListToExclude),:); %pick out child-directed adult vocs ONLY
            %Note that we don't have to do this for the merged tables because we do have all adult vocs and chil-directed adult vocs ONLY cases for the merged tables
        end
    
        if ~isequal(MergedTab,UnmergedTab) %if Merged and unmerged tables are not equal
            MergedLines = setdiff(MergedTab,UnmergedTab); UnmergedLines = setdiff(UnmergedTab,MergedTab); %get the set of merged and unmerged lines using setdiff.
            %The merged and unmerged tables will differ only for the vocs that have been merged, so setdiff both ways should pick these up.
    
            for j = 1:numel(height(MergedLines)) %go through the list of merged lines
                %For each merged voc, get the corresponding set of unmerged vocs, where successive vocs are sepaarted by 0 Ivi. 
                UnmergedSubset = UnmergedLines(UnmergedLines.start >= MergedLines.start(j) & UnmergedLines.xEnd <= MergedLines.xEnd(j)...
                    & strcmp(UnmergedLines.FileNameUnMerged,MergedLines.FileNameUnMerged{j}) ...
                    & (UnmergedLines.SectionNum == MergedLines.SectionNum(j)),:);
                if numel(unique(UnmergedSubset.speaker)) > 1 %if there is more than one speaker type, throw error
                    error('More than one speaker type in the unmerged set of vocs corresponding to a merged voc')
                end
                
                Spkrtype = unique(UnmergedSubset.speaker); %get the speaker type

                if numel(unique(UnmergedSubset.Annotation)) > 1 %if there is more than one unique annotation type
                    switch Spkrtype{1} %increment counter type accordingly
                        case 'AN'
                            AnVocMergeCtr = AnVocMergeCtr + 1;
                        case 'CHNSP'
                            ChnspVocMergeCtr = ChnspVocMergeCtr + 1;
                        case 'CHNNSP'
                            ChnnspVocMergeCtr = ChnnspVocMergeCtr + 1;
                    end
                end
            end
        end
    end
end
