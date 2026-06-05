clear; clc

%%@author info, JUne 2022
%code to check and flag
    %(comparing adult utt dir and adult orthographic transcription tiers) - are there annoations in the ortho tier that are missing from the
            %utterance direction tier? (while ideally, there are other tiers that this matching should be performed for completeness, the only tiers relevant to the 
            % burstiness paper are adult utterance direction and infant voc type. As such, further checking is unnecessary for the scope of this paper. This specific
            % check was to see if there are vocs that were annotated in the adult orthographic tier but not present in the adult utterance direction tier. This testing
            % was expanded to also check whether vocs in any one of adult utterance direction, adult orthographic transcription, music, or background overlap, were missing
            % any of othe other tiers in this list. This additional check was for JM's work on musical input to infants.)
    %tier mismatch - eg. when adult orth annotations are in adult utterance dir tier and vice-versa
    %missing annotations (annotations are empty)
    %non-sensical annotations (eg. W, O, ~, etc.)
    %annotations outside coding sporeadsheet bds

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%CHNAGE PATH(S) ACCORDINGLY
BasePath = '~/BaseDataPath/Data/HUMLabelData/';%This is the base path to the google drive folder that may undergo change
%read coding spreadsheet info file
CodingSpreadsheet = readtable(strcat(BasePath,'A1_HUMLabelData_CleanupPipeline/SummaryCsvAndTxtFiles/FNSTETSimplified.csv'));
CleanUpStatus = 'PreCleanUp'; %CHANGE TO 'PostCleanUp-CodeOnly', 'PreCleanUp', or 'PostCleanUp-CodeAndJM' ACCORDINGLY
if strcmpi(CleanUpStatus,'PreCleanUp')
    EafDetailsFromR_path = strcat(BasePath,'A1_HUMLabelData_CleanupPipeline/A2_ParsedEafFilesFromR_PreCleanUp/'); 
    CsvSuffixForCodingSpreadsheetBds = '_PreCleanUp.csv'; %_EditedMay2023
elseif strcmpi(CleanUpStatus,'PostCleanUp-CodeOnly') %for when files are from after automated clean up ONLY
    EafDetailsFromR_path = strcat(BasePath,'A1_HUMLabelData_CleanupPipeline/A4_ParsedEafFilesFromR_PostCleanUp/'); 
    CsvSuffixForCodingSpreadsheetBds = '_Edited.csv';
elseif strcmpi(CleanUpStatus,'PostCleanUp-CodeAndManual') %for when files are from after automated clean up and manual cleanup
    EafDetailsFromR_path = strcat(BasePath,'A2_HUMLabelData_PostCleanUp/A2_HlabelCsvFiles/');
    CsvSuffixForCodingSpreadsheetBds = '_EditedMay2023.csv';
end
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------

cd(EafDetailsFromR_path)
FilesFromR_dir = dir('*.csv'); %get list of files

%create empaty table to populate with mismatched or missing/incorrect annotations
T_TierMismatchOrIncorrectAnnot = array2table(zeros(0,12));
T_TierMismatchOrIncorrectAnnot.Properties.VariableNames = {'StartTimeRef','StartTimeLineNum','EndTimeRef','EndTimeLineNum','AnnotId',...
                    'AnnotIdLineNum','Annotation','AnnotationLineNum','TierTypeVec','StartTimeVal','EndTimeVal','EafFname'};

%create empaty table to populate with annotations that are not present in orthographic tier but not utterance dir tier
T_AnnotInOrthoTierButNotAdultUttDirTier = array2table(zeros(0,12));
T_AnnotInOrthoTierButNotAdultUttDirTier.Properties.VariableNames = {'StartTimeRef','StartTimeLineNum','EndTimeRef','EndTimeLineNum','AnnotId',...
                    'AnnotIdLineNum','Annotation','AnnotationLineNum','TierTypeVec','StartTimeVal','EndTimeVal','EafFname'};

%finally, empty table to store start time greater than end time instances
T_StartTimeGreaterThanEndTime = array2table(zeros(0,12));
T_StartTimeGreaterThanEndTime.Properties.VariableNames = {'StartTimeRef','StartTimeLineNum','EndTimeRef','EndTimeLineNum','AnnotId',...
    'AnnotIdLineNum','Annotation','AnnotationLineNum','TierTypeVec','StartTimeVal','EndTimeVal','EafFname'};

for i = 1:numel(FilesFromR_dir)
    TierInfoTable = readtable(FilesFromR_dir(i).name,'Delimiter',','); %Clumn names: StartTimeRef, StartTimeLineNum, EndTimeRef, EndTimeLineNum, AnnotId, AnnotIdLineNum, Annotation, AnnotationLineNum
    %TierTypeVec, StartTimeVal, EndTimeVal, 

    %add column with file name to table
    EafFnRoot = erase(FilesFromR_dir(i).name,CsvSuffixForCodingSpreadsheetBds); %get file name root
    FileNameVec = cell(size(TierInfoTable.StartTimeRef));
    [FileNameVec{:}] = deal(EafFnRoot);
    TierInfoTable.EafFname = FileNameVec;

    %%Looking  at mismatched or otherwise incorrect annotation---------------------------------------------------------------------------------------------------------
    %the function recursively fills out the predefined table with whichever row form a file that has incorrect or mismatched annotation
    %we are only doing this for the infant voc type and adult utt direction tiers
    T_TierMismatchOrIncorrectAnnot = GetMismatchedTierAndIncorrectAnnotations(TierInfoTable,T_TierMismatchOrIncorrectAnnot);

    %%The second layer of finding misisng annottaions: check if all annotations in adult utt dir tier are in orthographic tier and vice-versa--------------------------
    %Note that we also look for cases where an annotation is in adult utt dir tier but not in music tier or vice-versa; in adult utt dir tier but not in background overlap 
    % tier or vice-versa
    T_AnnotInOrthoTierButNotAdultUttDirTier = GetAnnotInOrthoButNotInUttDir(TierInfoTable,FilesFromR_dir(i).name,T_AnnotInOrthoTierButNotAdultUttDirTier);

    for j = 1:numel(TierInfoTable.StartTimeVal)
        if TierInfoTable.StartTimeVal(j) > TierInfoTable.EndTimeVal(j)
            Tnew = TierInfoTable(j,:);
            T_StartTimeGreaterThanEndTime = [T_StartTimeGreaterThanEndTime; Tnew];
        end
    end
end

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%CHNAGE PATH(S) ACCORDINGLY
cd(strcat(BasePath,'A1_HUMLabelData_CleanupPipeline/SummaryCsvAndTxtFiles/')) %go to destination
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------

fileID = fopen(strcat(CleanUpStatus,'EafCodingSpreadsheetMissingFilesSummary.txt'),'w'); %creates new file to write to; 'w' indicates this
T_AnnotOutsideCodingSheetBds = GetAnnotOutsideCodingSheetBds(CodingSpreadsheet,FilesFromR_dir,fileID,CsvSuffixForCodingSpreadsheetBds); %gte summary table with info about annots outside codingsheet bds
fclose(fileID);
T_RogueInfAdultAnnots = GetRogueInfOrAdultAnnotsInOtherTiers(FilesFromR_dir,CsvSuffixForCodingSpreadsheetBds);

%save tables
writetable(T_AnnotInOrthoTierButNotAdultUttDirTier,strcat(CleanUpStatus,'Summary_AnnotsForVocsInOrthoButMissingInUttDir.csv'))
writetable(T_TierMismatchOrIncorrectAnnot,strcat(CleanUpStatus,'Summary_MissingAnnot_TierMismatch_IncorrectAnnot.csv'))
writetable(T_StartTimeGreaterThanEndTime,strcat(CleanUpStatus,'Summary_StartTGreaterThanEndT.csv'))
writetable(T_AnnotOutsideCodingSheetBds,strcat(CleanUpStatus,'AnnotsOutsideCodingSheetBds.csv'))
writetable(T_RogueInfAdultAnnots,strcat(CleanUpStatus,'Summary_RogueInfAdultAnnotsInOtherTiers.csv'))
