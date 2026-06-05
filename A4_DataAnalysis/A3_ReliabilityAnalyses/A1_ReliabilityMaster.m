clear; clc

%@author info, June 2024
%Reliability code: this script estimates reliability measures between human-listener labelled 5 minute sections and corresponding LENA sections, by computing the following metrics:
% false alarm rate, miss rate, confusion rate, identification error rate, precision, and recall, per Cristia et al, 2021. Note that we use 1 ms frames as opposed to Cristia et al's 
% 10 ms frames, because the human listener labels are determined to 0.001 seconds.

%"These are calculated with the following formulas at the level of each clip, where:
    %- FA (false alarm) is the number of frames during which there is no talk according to the human annotator but during which LENA® found some talk; 
    %- M (miss) is the number of frames during which there is talk according to the human annotator but during which LENA® found no talk; 
    %- C (confusion) is the number of frames correctly classified by LENA® as containing talk, but whose voice type has not been correctly identified (when the LENA® model 
        % recognizes female adult speech where there is male adult speech for instance)
    %- T is the total number of frames that contain talk according to the human annotation
%Then, False alarm rate = FA/T; miss rate = M/T; confusion rate = C/T; Id error rate = (FA + M + C)/T

%This script ALSO computes the Precision and recall confusion matrices to quantify human-LENA inter-rater reliability, as described in Cristia et al, 2021. Note that we use 1 ms 
% frames as opposed to Cristia et al's 10 ms frames, because the human listener labels are determined to 0.001 seconds.

%Precision is a measure of LENA's precision, i.e, for each category, it is the number of frames LENA and human annotator agree on, divided by the total number of frames LENA labelled as that
    % category. That is, it is ratio of how often LENA was correct for a category (eg. CHNSP) and how often LENA overall labelled that category. Put more simply, it is a measure of how often
    % was LENA correct.
    %In the confusion matrix for precision, the (i,j)th element--where human labels are indexed by  i (the row index; true values) and the LENA labels are indexed by j (the col index; test 
        % values)-- is given by the number of frames labelled as category j by LENA that are labelled as category i by the human listener, divided by the total number of frames that 
        % are labelled j by LENA. That is, the (i,j)th element is the proportion of frames that are labelled j by LENA that correspond to category i as labelled by the human listener.
        % Note that every column sums to 1. 
%Recall is a measure of how much of the 'correct' tag (as labelled by the human annotator) did LENA accurately identitfy (or recalled/recovered). So, this is the number of frames LENA and 
    % human annotator agree on for a category divided by the number of frames the human annotator id'd as that category.
    %In the confusion matrix for recall, the (i,j)th element--where human labels are indexed by  i (the row index; true values) and the LENA labels are indexed by j (the col index; test 
        % values)-- is given by the number of frames labelled as category j by LENA that are labelled as category i by the human listener, divided by the total number of frames that 
        % are labelled i by the human listener. That is, the (i,j)th element is the proportion of frames that are labelled j by LENA that correspond to category i as labelled by the human 
        % listener. Note that every row sums to 1. 
    % Also note that for precision and recall, the numerator remains the same, and it is the denominator that changes.
%-------------------------------------------------------------------------------------------------------------------------
% ----------------------------------------------------------
%CHANGE PATHS AND INPUT STRINGS ACCORDINGLY
BasePath = '~/BaseDataPath/Data/'; %set base path
UnannotatedFiles = readtable(strcat(BasePath,'MetadataFiles/FilesWithUnannotatedSections.csv')); %read in file with info about unannotated sections
CodingSheet = readtable(strcat(BasePath,'HUMLabelData/A1_HUMLabelData_CleanupPipeline/SummaryCsvAndTxtFiles/FNSTETSimplified.csv')); %read in coding spreadsheet
MetaData = readtable(strcat(BasePath,'MetadataFiles/MergedTSAcousticsMetadata.csv'));

Hum_AllAdVocs_FilesPath = strcat(BasePath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A9_NoAcoustics_0IviMerged_Hum/'); %get path to human listener labelled files all adult vocs considered
cd(Hum_AllAdVocs_FilesPath); StrForDir_H_AllAd = '*_NoAcoustics_0IviMerged_Hum.csv'; %read in files
HumFiles_AllAd = dir(StrForDir_H_AllAd); 

%get path to human listener labelled file (only infant-directed adult vocs)
Hum_ChildDirANOnly_FilesPath = strcat(BasePath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A11_NoAcoustics_0IviMerged_Hum_ChildDirANOnly/'); 
cd(Hum_ChildDirANOnly_FilesPath); StrForDir_H_ChildDirANOnly = '*_NoAcoustics_0IviMerged_ChildDirANOnly_Hum.csv'; %read in files
Hum_ChildDirANOnly_Files = dir(StrForDir_H_ChildDirANOnly); 

LENAFilesPath = strcat(BasePath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A10_NoAcoustics_0IviMerged_L5min/');%get path to corresponding LENA labelled files
cd(LENAFilesPath); LENAFiles = dir('*_NoAcoustics_0IviMerged_LENA5min.csv'); %read in files
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

%make cell arrays for for loop
HumFileList = {HumFiles_AllAd,Hum_ChildDirANOnly_Files}; %list of the different types of human labelled files (all AN vocs or child-directed AN vocs only)
HumStrForDirList = {StrForDir_H_AllAd,StrForDir_H_ChildDirANOnly}; %list of the strings for the different types of human labelled files 
HumDataAdultVocType = {'All','ChildDir'}; %strings to identify the adult voc class 
SectionOrFileLevel = {'section','file'}; %list of strings id-ing whether error rates are computed at the 5 min section level or the file level

%initialise final output tables and assign variable names
ReliabilityNumsTab_Agg = array2table(zeros(0,23));
ReliabilityNumsTab_Agg.Properties.VariableNames = {'NumFrameMatch_CHNSP','NumFrameMatch_CHNNSP','NumFrameMatch_AN','NumFrameMatch_NA-NotLab',...
                                               'NumFramesLENA_CHNSP','NumFramesLENA_CHNNSP','NumFramesLENA_AN','NumFramesLENA_NA-NotLab',...
                                               'NumFramesHum_CHNSP','NumFramesHum_CHNNSP','NumFramesHum_AN','NumFramesHum_NA-NotLab',...
                                               'NumFA','NumMiss','NumConf','NumConfCHN','NumSpeech_Hum','CohensKappa','PercentAgreement',...
                                               'Fname','AgeMonths','SecOrFileLvl','AN_Type'};

%get tables with validation numbers for human labels with all (T, U, N) adult vocs and only child-directed adult vocs, separately, as well as for computations at the section level and 
% file level.

VocLabelSet = {'CHNSP','CHNNSP','AN','NA-NotLab'}; %Set of unique speaker lables to compute porecisoon and recall matrices
WarningOnOrOff = 1; %toggle warnings on for the step that returns 1 ms segments
Ctr = 0; %initialise counter variable
for i = 1:numel(HumFileList)
    for j = 1:numel(SectionOrFileLevel)
        Ctr = Ctr + 1;
        [ReliabilityNumsTab,ConfusionStruct(Ctr).LabelSetIntersectNums_Cell,ConfusionStruct(Ctr).NumDenom_Prec_RowVec_Cell,...
            ConfusionStruct(Ctr).NumDenom_Recall_ColVec_Cell] = GetValidationSummaryNums(LENAFiles,HumFileList{i},HumStrForDirList{i},CodingSheet,UnannotatedFiles,...
                                                                                         SectionOrFileLevel{j},MetaData,WarningOnOrOff,VocLabelSet);
        ConfusionStruct(Ctr).HumAdultVocType = HumDataAdultVocType{i}; %store the adult voc category type
        ConfusionStruct(Ctr).SecOrFileLvl = SectionOrFileLevel{j}; %store info about section or file level
        ReliabilityNumsTab_Agg = [ReliabilityNumsTab_Agg; ReliabilityNumsTab]; %add to aggregate output table
        WarningOnOrOff = 0; %toggle warnings off for the step that returns 1 ms segments
    end
end

MasterChecksForReliability_HumVsLENA(ReliabilityNumsTab_Agg, ConfusionStruct, VocLabelSet) %do final checks

cd(strcat(BasePath,'/ResultsTabs/ReliabilityTabs/')); %go to path to write tables
writetable(ReliabilityNumsTab_Agg,'ReliabilityErrorRates_FileOrSectionLvl.csv'); %write tabs to file
save('ConfusionMatStruct.mat',"ConfusionStruct")

%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
% Thsi function takes in the following inputs:
    %- LENAFiles: list of LENA 5 min files 
    %- HumFiles: the list of human-listener labelled files (all adult vocs or child directed adult vocs ONLY)
    %- StrForDir_H: the string we use to dir files from the human label directory
    %- CodingSheet: coding spreadsheet with info about sections flagged for annotation
    %- UnannotatedFiles: the spreadhseet with info about partually annotated files
    %- SectionOrFileLevel: a string determining whether we want error rates calculated at the section level (to see variation at the section level) or at the level 
        % of each file (consisting of multiple annotated sections)
    %- MetaData: the metadata file
    %- WarningOnOrOff: logical TRUE or FALSE; simply toggles warnings on or off in the function that returns 1 ms frames ONLY (we only want the warnings issues the first combo of:
        % 1. section level vs file level error computing, and 2. all adult vocs or child directed adult vocs only, as labelled by the human listener. 
    %- VocLabelSet: Set of unique speaker lables to compute porecisoon and recall matrices

    %The outputs are: 
        %- ReliabilityNumsTab: table with various reliability numbers 
        %- LabelSetIntersectNums_Cell: cell array with the confusion matrices for each file or section (as specified by SectionOrFileLevel)
        %- NumDenom_Prec_RowVec_Cell: cell array with the row vector with the total numer of each frames as id'd by LENA (this becomes the denominator to compute precision), 
            % for each section or file
        %- NumDenom_Recall_ColVec_Cell: cell array with the col vector with the total numer of each frames as id'd by human annotator (this becomes the denominator to 
            % compute recall), for each section or file
   
function [ReliabilityNumsTab,LabelSetIntersectNums_Cell,NumDenom_Prec_RowVec_Cell,NumDenom_Recall_ColVec_Cell] ...
                                    = GetValidationSummaryNums(LENAFiles,HumFiles,StrForDir_H,CodingSheet,UnannotatedFiles,SectionOrFileLevel,MetaData,WarningOnOrOff,VocLabelSet)

    %We implement two checks: one to make sure that there are no errors in the 1 ms vocalisation chunk generation and one to make sure that the computation of precision and recall matrices
    % and well as the error rates is correct. In order to reduce the computational effort that goes into these checks, instead of doing this check for ALL files, we do it for a 10 randomly
    % selected files. 
    RndFileIndex = randi(numel(HumFiles),[1 10]); %Generae 10 random indices corresponding to 10 files to do the checks
    %RndFileIndex = randi(10,[1 10]);

    %first check if both lena and human files have the same number of files.
    if numel(HumFiles) ~= numel(LENAFiles)
        warning('Number of human-labelled files and corresponding LENA files is not equal')
    end
    
    H_StrToRemove = erase(StrForDir_H,'*'); %remove the * character from the fie name (the * was to faciliatet dir)
    Ctr = 0; %initialise counter variable, valid only if we are looking at error rates at the 5 miniute section level
   
    for i = 1:numel(HumFiles) %go through list of human-labelled files

        %Check if the current file index is part of the random list of file indices generated to check for errors in the 1 ms voc chunk generation and the computation of precision and recall
        % matrices as well as error rates.
        ErrorCheck = ismember(i,RndFileIndex);

        %check if the human listener labelled file name and the LENA 5 min file name match
        if ~strcmp(erase(HumFiles(i).name,H_StrToRemove),erase(LENAFiles(i).name,'_NoAcoustics_0IviMerged_LENA5min.csv'))
            warning('Human-labelled file root and LENA file-root of the ith files in respective directories do not match: %s',erase(HumFiles(i).name,H_StrToRemove))
        else
            FnameRoot = erase(HumFiles(i).name,H_StrToRemove); %get file name root
            CodingSubsheet = CodingSheet(contains(CodingSheet.FileName,FnameRoot),:); %get coding spreadsheet start and end times
            Hfile = readtable(HumFiles(i).name); Lfile = readtable(LENAFiles(i).name); %read human-listener labelled files
            [Hfile, NumAnnotSecs_H] = Get1msVocChunks(Hfile,CodingSubsheet,WarningOnOrOff,ErrorCheck); 
            [Lfile, NumAnnotSecs_L] = Get1msVocChunks(Lfile,CodingSubsheet,0,ErrorCheck); %get 1 ms frames; WarningOnOrOff set to default FALSE for LENA
            if (height(Hfile) ~= NumAnnotSecs_H*300000) && strcmp(SectionOrFileLevel,'file')
                disp('yo')
            end

            if ~isequal(Hfile.start,Lfile.start) || ~isequal(Hfile.xEnd,Lfile.xEnd)
                error('List of start or end times for human and LENA 5 min files ')
            end
    
            %check if the number of annotated sections in the human listener file and the LENA 5 min file are the same.
            if NumAnnotSecs_L ~= NumAnnotSecs_H
                warning('Different number of sections in the LENA and human-listener labelled file: %s', FnameRoot)
            end
    
            %check if there are less or more than 3 sections annotated, the number of annotated sections and number of unannotatted section match with info in csv file taht flags this info.
            if (NumAnnotSecs_H ~= 3) && (height(CodingSubsheet) ~= NumAnnotSecs_H) %this second condition is to make sure we are only flagging situations where there are n number
                %of sections determined to be annotated in the coding sheet, but there are nn number of sectons actually annotated, such that n ~= nn. That is, we only flag when the number
                % of actually annotated sections does not match the number of sections flagged for annotation. 
                SubTab = UnannotatedFiles(strcmp(UnannotatedFiles.Fname_UnannotSections,FnameRoot),:); %subset the info for partially annotated files for the given filename
                if ~isempty(SubTab) %if this subsetted table is not empty
                    if SubTab.NumSectionsAnnotated ~= NumAnnotSecs_H %check if number of annotated sections in the csv file matches the actual number of annoated sections
                        warning('Number of actual annotated sections does not match number of sections annoated per csv file: %s', FnameRoot)
                    end
                else
                    warning('The subsetted table is empty (but it should not be): %s', FnameRoot)
                end
            end

            %switch-case loop depending on if we want error rates computed at the level of each 5 min section or at the level of each file
            switch SectionOrFileLevel 
                case 'section' %we use the section level numbers merely to see variation in precision and recall numbers for each category, eg. CHNSP precison and recall, etc. 
                    for j = 1:height(CodingSubsheet) %go through list of sections in coding sheet for the file                                          
                        HSub = Hfile(Hfile.start >= CodingSubsheet.StartTimeSS(j) &   Hfile.xEnd <= CodingSubsheet.EndTimeSS(j),:); %get corresponding subsetted tables. This works
                        % because in getting the 1 ms seconds, we including every 1 ms from the start to teh end of the section to be annotated (i.e, the entire five minute stretch) per 
                        % the coding spreadsheet.
                        LSub = Lfile(Lfile.start >= CodingSubsheet.StartTimeSS(j) &   Lfile.xEnd <= CodingSubsheet.EndTimeSS(j),:); 
                        if ~isempty(HSub) && ~isempty(LSub) && strcmp(HSub.FileNameUnMerged{1},LSub.FileNameUnMerged{1})%if both subsetted tables are NOT empty AND if the unmerged file name
                            %matches for human listener label vs LENA label
                            Ctr = Ctr + 1; %increment counter
                            Fname{Ctr,1} = FnameRoot;
                            AgeMonths(Ctr,1) = MetaData(contains(MetaData.FileNameRoot,FnameRoot),:).InfantAgeMonth; %get infant age

                            %Get arrays to compute precision and recall. Note that each cell array element of NumDenom_PrecisionRowVec is a row vector, where the jth element of the row 
                            % vector corresponds to the number of frames id'd as label category j from VocLabels by LENA. For NumDenom_RecallColVec, each cell array element is a column 
                            % vector, where the jth element corresponds to the number of frames id'd as label category j by human annotator. 
                            [LabelSetIntersectNums_Cell{Ctr,1},NumDenom_Prec_RowVec_Cell{Ctr,1},NumDenom_Recall_ColVec_Cell{1,Ctr},CohensKappa(Ctr,1),PercentAgreement(Ctr,1)] = ...
                                                                                                    GetPrecisionAndRecallMats(HSub, LSub, VocLabelSet);
                            %get number of false alarms, confusions, and misses 
                            [NumFA(Ctr,1),NumMiss(Ctr,1),NumConf(Ctr,1),NumConfCHN(Ctr,1),NumSpeech_Hum(Ctr,1)] = ...
                                                                                                    GetReliabilityErrorNum(LabelSetIntersectNums_Cell{Ctr,1},VocLabelSet);

                        elseif isempty(HSub) && isempty(LSub) 
                            warning('Section not annotated: %s',FnameRoot)
                        elseif ~strcmp(HSub.FileNameUnMerged{1},LSub.FileNameUnMerged{1})
                            warning('Wow, unmerged file names do not match between human labelled and LENA labelled file: %s', FnameRoot)
                        end
                    end
                case 'file'
                    %get arrays to compute precision and recall, as well as number of false alarms, confusions, and misses 
                    [LabelSetIntersectNums_Cell{i,1},NumDenom_Prec_RowVec_Cell{i,1},NumDenom_Recall_ColVec_Cell{1,i},CohensKappa(i,1),PercentAgreement(i,1)] = ...
                                                                                                                    GetPrecisionAndRecallMats(Hfile, Lfile, VocLabelSet); 
                    [NumFA(i,1),NumMiss(i,1),NumConf(i,1),NumConfCHN(i,1),NumSpeech_Hum(i,1)] = GetReliabilityErrorNum(LabelSetIntersectNums_Cell{i,1},VocLabelSet); 
                    if ErrorCheck %if file is one of the files indexed for random error check. 
                        CheckReliabilityNumFrames_MatlabVsUser(Hfile, Lfile, VocLabelSet,...
                                                LabelSetIntersectNums_Cell{i,1}, NumDenom_Prec_RowVec_Cell{i,1}, NumDenom_Recall_ColVec_Cell{1,i}, ...
                                                NumFA(i,1),NumMiss(i,1),NumConf(i,1),NumConfCHN(i,1))
                    end
                    Fname{i,1} = FnameRoot;
                    AgeMonths(i,1) = MetaData(contains(MetaData.FileNameRoot,FnameRoot),:).InfantAgeMonth; %get infant age
            end                                                      
        end
    end

    %Here, we get section or file level precision and recall details for each label, so we get CHNSP-to-CHNSP, CHNNSP-to-CHNNSP, AN-to-AN, and NA-NotLab-to-NA-NotLab precison and recall 
    %values, for each file/section, as specified. 

    % Now, LabelSetIntersectNums_Cell is a cell array where each element in the cell array is an NxN matrix (where N = numel(VocLabelSet). The diagonal elements of this NxN matrix 
    % correspond to the number of frames where LENA and human annotator agree on the corresponding vocal label. That is, the ith diagonal element is the number of frames where there is 
    % agreement between LENA and human annotator taht the label is the ith element of VocLabelSet. These are the numbers we are pulling out in the for loop below. By indexing as {1,i}, 
    % where i is the index of the voclabel category (eg. CHNSP, CHNNSP, etc.), we get a single row cell arry with N columns, where N = numel(VocLabels). So, NumFrameMatch_Label_i is a 
    % cell array where the ith column (after cell2mat-ing) is a column vector consisting of the ith diagonal element of the confusion matrix, corresponding to the number of frames LENA 
    % and human annotator agreed on the ith VocLabel, for every file/section).

    % NumDenom_Prec_RowVec_Cell is a cell array where each element in the cell array is a row vector with length = numel(VocLabelSet). NumDenom_Recall_ColVec_Cell is a cell array where 
    % each element in the cell array is a column vector with length = numel(VocLabelSet).
    for i = 1:numel(VocLabelSet) %go through the set of unique labels
        NumFrameMatch_Label_i{1,i}= cell2mat(cellfun(@(x)x(i,i),LabelSetIntersectNums_Cell,'UniformOutput',false)); %get the number of matchinhg frames for LENA and human annotator for label 
        % category i (this will be the numerator for both recall and precision for that label category). The cellfun picks out the diagonal element correspodning to the number of frames 
        % where LENA and human annotator agreed on the ith VocLabel.
    end
     
    %get the rest of the output table columns
    SecOrFileLvl = cell(size(Fname)); SecOrFileLvl(1:end) = {SectionOrFileLevel}; %SecOrFileLvl vector, which specifies if we are computing rates at the 5 min section level or file level
    AN_Type = cell(size(Fname)); %initialise the AN_Type vector, which specifies if we are computing rates for all adult vocs or only child directed adult vocs, as id'd by human listener
    AN_TypeStr = erase(StrForDir_H,'_NoAcoustics_0IviMerged_');
    if contains(AN_TypeStr,'ChildDirANOnly') %assign the string type
        AN_Type(1:end) = {'ChildDir'};
    else
        AN_Type(1:end) = {'All'};
    end
   
    %make output tables
    %1. make table for precision and recall numbers (note that these are the number of frames taht go into calculating prcison and recall). Note that NumFrameMatch_Label_i is a 
    % 1-by-numel(VocLabels) cell array, where the ith element of the cell array is an N-by-1 array, where N = toal number of sections/files. Cell2mat-ing this gives an N-by-numel(VocLabels) 
    % array where the i-th column gives the number of frames id'd by both LENA and human annotator as the i-th voc label category for that section/file. NumDenom_PrecisionRowVec is an N-by-1
    % cell array where each element is a row vector of size 1-by-numel(VocLabels). Cell2mat-ing this similarly gives an N-by-numel(VocLabels) array where the i-th column gives the number of 
    % frames id'd by LENA as the i-th voc label category for that section/file. Finally,NumDenom_RecallColVec is an N-by-1 cell array where each element is a column vector of size 
    % 1-by-numel(VocLabels). Cell2mat-ing a*and* transposing (in that order) gives an N-by-numel(VocLabels) array where the i-th column gives the number of frames id'd by human annotator 
    % as the i-th voc label category for that section/file
    PrecRecallNumFramesTab = array2table([cell2mat(NumFrameMatch_Label_i) cell2mat(NumDenom_Prec_RowVec_Cell) cell2mat(NumDenom_Recall_ColVec_Cell)']); 
    PrecRecallNumFramesTab_VarNames = [strcat('NumFrameMatch_',VocLabelSet) strcat('NumFramesLENA_',VocLabelSet) strcat('NumFramesHum_',VocLabelSet)]; %make column names for thsi table
    PrecRecallNumFramesTab.Properties.VariableNames = PrecRecallNumFramesTab_VarNames; %set column names
    %2. Get error rates in table
    ReliabilityNumsTab = table(NumFA,NumMiss,NumConf,NumConfCHN,NumSpeech_Hum,CohensKappa,PercentAgreement,Fname,AgeMonths,SecOrFileLvl,AN_Type); 
    %3. Add precision and recall frame numbers table to error rate table
    ReliabilityNumsTab = [PrecRecallNumFramesTab ReliabilityNumsTab];
end





