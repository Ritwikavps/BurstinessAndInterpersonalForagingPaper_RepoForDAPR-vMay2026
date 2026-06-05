%@author info, Oct 2024: 
% Functions to get summary numbers from data (eg. total number and duration of vocs in each recording for each dataset: LENA day long, LENA 5 min, Hum 5 min).
% The summary numbers are: 
%           - Total number of vocs in each file + breakdown by type and age + mean number of total vocs and each type voc (overall and by age); and
%           - Total duration of vocs in each file + breakdown by type and age + mean number of total vocs and each type voc (overall and by age)
% 
% Inputs: - DatasetType: cell array of strings identifying the data set types ('Lday';'L5min';'H5min-AllAd')
%         - DataDir: cell array with dir-d lists of files in each dataset
%         - MetadataTab: table with metadata info
%         - AgeMonth: vector of unique ages (3, 6, 9, 18 mo)
%
% Outputs: - TabsNums_FileLvl: cell array of tables with number of voc or annotation type breakdown as well as file name root and infant age. i-th table in the array corresponds to
%                               to the i-th dataset type.
%          - ByAgeAndVocTypeNumsTabs: cell array with tables with tot vocs number by age and vocalisation type (at different levels, so this would include CHN/AN levl, 
%                                   CHNSP/CHNNSP/AN level and if applicable, annotation tag level)
%          - ByVocTypeNumsTabs: cell array with tables with total numbers by voc type only
%          - ByAgeNumsTabs: cell array with tables with total numbers by age only
%          - TotNums: cell array with tables with total number of vocs of each type in each dataset.
%          - TabsDur_FileLvl, ByAgeAndVocTypeDurTabs, ByVocTypeDurTabs, ByAgeDurTabs, TotDur: similarly as above, but for duration of vocs instead of number of vocs.

function [TabsNums_FileLvl, ByAgeAndVocTypeNumsTabs, ByVocTypeNumsTabs, ByAgeNumsTabs,... 
              TabsDur_FileLvl, ByAgeAndVocTypeDurTabs, ByVocTypeDurTabs, ByAgeDurTabs, TotNums, TotDur] = GetDataSummaryDetails(DatasetType,DataDir,MetadataTab,AgeMonth)
    
    uVocType_LENA = {'CHNSP','CHNNSP','AN'}; uVocType_Hum = {'T','U','N','C','X','R','L'}; %get list of unique vocaliser/annotation tags
    %DatasetType = {'Lday';'L5min';'H5min-AllAd'}; %for reference
    uVocType = {uVocType_LENA,uVocType_LENA,uVocType_Hum}; %put these two vectors above in the same order as DataDir and DatasetType, so we can use it in the for loop below
    
    for ii = 1:numel(DatasetType) %go through data set type list
        [TabsNums_FileLvl{ii}, ByAgeAndVocTypeNumsTabs{ii}, ByVocTypeNumsTabs{ii}, ByAgeNumsTabs{ii},... %get number of vocs and total duration of vocs by each type 
                  TabsDur_FileLvl{ii}, ByAgeAndVocTypeDurTabs{ii}, ByVocTypeDurTabs{ii}, ByAgeDurTabs{ii}] = GetGranularNumVocTotals(DataDir{ii},uVocType{ii},MetadataTab,AgeMonth);
        % at the file level, as well as voc num totals organised by age and voc type, using user-defined function (see below)
    end
    
    for ii = 1:numel(TabsNums_FileLvl) %go through the output cell and get the total numbers and total duration
        OpTabCurr_Num = TabsNums_FileLvl{ii};
        TotNums{ii,1} = sum(OpTabCurr_Num(:,1:end-3)); %the last three columns are filename, age, and number of sections, so can remove that
        OpTabCurr_Dur = TabsDur_FileLvl{ii};
        TotDur{ii,1} = sum(OpTabCurr_Dur(:,1:end-3));
    end


%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%Functions used:
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    %This function gets  the number of vocs and total duration of vocs for each vocaliser and (if applicable) annotation type at the file level, for each dataset type.
    %It also gets the total number of utterances by age and voc type in a table.
    % Inputs: - DataDir: list of files in teh relevant directory
    %         - uVocType: list of unique vocaliser or annotation tags (as applicable)
    %         - MetadataTab: table with metadata info
    %         - AgeMonth: vector of unique ages (3, 6, 9, 18 mo)
    % 
    % Output: - OpTabNums_FileLvl: table with number of voc or annotation type breakdown as well as file name root and infant age.
    %         - ByAgeAndVocTypeNumsTab: table with tot vocs number by age and vocalisation type (at different levels, so this would include CHN/AN levl, CHNSP/CHNNSP/AN level and 
    %                                   if applicable, annotation tag level)
    %         - ByVocTypeNumsTab: table with total numbers by voc type only
    %         - ByAgeNumsTab: table with total numbers by age only
    %         - OpTabDur_FileLvl, ByAgeAndVocTypeDurTab, ByVocTypeDurTab, ByAgeDurTab: similarly as above, but for duration of vocs instead of number of vocs
    
    function [OpTabNums_FileLvl, ByAgeAndVocTypeNumsTab, ByVocTypeNumsTab, ByAgeNumsTab,...
              OpTabDur_FileLvl, ByAgeAndVocTypeDurTab, ByVocTypeDurTab, ByAgeDurTab] = GetGranularNumVocTotals(DataDir,uVocType,MetadataTab,AgeMonth)

        for i = 1:numel(DataDir) %go through list of files
            DataTab = readtable(DataDir(i).name); %read in table
            if ~ismember('Annotation',DataTab.Properties.VariableNames) %if annotation is not a variable name in the table, we know this is not human-labelled data, so we can pick out the
                % relevant column with vocaliser/annotation tags based on this info.
                VectorwSpkrOrAnnots = DataTab.speaker; %get the speaker column if NOT human-annotated data
            else
                VectorwSpkrOrAnnots = DataTab.Annotation; %get the Annotation column if THIS IS human-annotated data
            end

            DataTab.Duration = DataTab.xEnd-DataTab.start; %add duration as a column
            if ~isequal(DataTab.Duration,DataTab.Duration(DataTab.Duration >= 0))  %error check to make sure there are no negative durations
                error('There are negative duration values!!')
            end
    
            for j = 1:numel(uVocType) %go through the list of available vocaliser/annotation tag and number of each type in the current table
                NumVocsByVocType(i,j) = numel(VectorwSpkrOrAnnots(ismember(VectorwSpkrOrAnnots,uVocType{j}))); %The indexing here is so that the row index is for the
                % file, and the column index is for the vocaliser or annotation type.
                DurVocsByVocType(i,j) = sum(DataTab.Duration(ismember(VectorwSpkrOrAnnots,uVocType{j}))); %do the same for duration
            end
    
            FileRoot{i,1} = DataDir(i).name(1:11); %get the file root based on the name of the file
            InfantAgeMonthsForTab(i,1) = MetadataTab(ismember(MetadataTab.FileNameRoot,FileRoot{i,1}),:).InfantAgeMonth;
            NumSectionsForTab(i,1) = numel(unique(DataTab.SectionNum)); %get number of sections
        end
    
        [OpTabNums_FileLvl,ByAgeAndVocTypeNumsTab,ByVocTypeNumsTab,ByAgeNumsTab] =...
                                                GetTotNumsOrDurOpTabs(NumVocsByVocType,uVocType,AgeMonth,'Num',FileRoot,InfantAgeMonthsForTab,NumSectionsForTab);
        [OpTabDur_FileLvl,ByAgeAndVocTypeDurTab,ByVocTypeDurTab,ByAgeDurTab] =...
                                                GetTotNumsOrDurOpTabs(DurVocsByVocType,uVocType,AgeMonth,'Dur',FileRoot,InfantAgeMonthsForTab,NumSectionsForTab);

    end
    
    %-----------------------------------------------------------------------------------------------------------
    % This function gets the file level total duration and number of vocs by type, as well as the total duration and number of vocs by age, by voc typpe, and by age and voc type.
    % Whether total duration or total number of vocs is computed is determined by the input NumOrDur.
    % 
    % Inputs: - NumsOrDurVocsByVocType: the array with file level total nums or total duration by voc type
    %         - uVocType: the list of unique voc types (at the lowest level: CHNSP, CHNNSP, AN for LENA data; annotations for Hum data)for the relevant data (human or LENA labelled)
    %         - AgeMonth: vector of unique ages (3, 6, 9, 18 mo)
    %         - NumOrDur: string specifying whether we are delaing duration totals or total nums
    %         - FileRoot, InfantAgeMonthsForTab, NumSectionsForTab: file root, infant age, and number of sections vectors corresponding to the files to go in the output table
    % 
    % Outputs: - OpTab_FileLvl: table with total number/duration of voc or annotation type breakdown as well as file name root and infant age.
    %          - ByAgeAndVocType_NumOrDur_Tab: table with tot vocs number/duration by age and vocalisation type (at different levels, so this would include CHN/AN levl, 
    %                                          CHNSP/CHNNSP/AN level and if applicable, annotation tag level)
    %          - ByVocType_NumOrDur_Tab: table with total numbers/duration by voc type only
    %          - ByAge_NumOrDur_Tab: table with total numbers/duration by age only.
    function [OpTab_FileLvl,ByAgeAndVocType_NumOrDur_Tab,ByVocType_NumOrDur_Tab,ByAge_NumOrDur_Tab] =...
                                                GetTotNumsOrDurOpTabs(NumsOrDurVocsByVocType,uVocType,AgeMonth,NumOrDur,FileRoot,InfantAgeMonthsForTab,NumSectionsForTab)
        
        OpTab_FileLvl = array2table(NumsOrDurVocsByVocType); %make output table by converting the input array to table.
        OpTab_FileLvl.Properties.VariableNames = uVocType; %recast variable names
        if ~ismember('CHNSP',OpTab_FileLvl.Properties.VariableNames) %Get number of CHNSP, CHNNSP, and AN vocs for human-annotated files (cuz we only have annotation tag-level 
            %--C,X,R,L,T,U,N--numbers for that); so, check if the table has a Num_CHNSP column
            OpTab_FileLvl.CHNSP = OpTab_FileLvl.C + OpTab_FileLvl.X; %CHNSP nums
            OpTab_FileLvl.CHNNSP = OpTab_FileLvl.R + OpTab_FileLvl.L; %CHNNSP nums
            OpTab_FileLvl.AN = OpTab_FileLvl.T + OpTab_FileLvl.U + OpTab_FileLvl.N; %AN nums
        end

        OpTab_FileLvl.CHN = OpTab_FileLvl.CHNSP + OpTab_FileLvl.CHNNSP; %Get total CHN nums
        OpTab_FileLvl.Tot = OpTab_FileLvl.CHN + OpTab_FileLvl.AN; %Get total number of vocs
        
        OpTab_FileLvl.Properties.VariableNames = strcat(NumOrDur,'_',OpTab_FileLvl.Properties.VariableNames); %recast variable names
        
        OpTab_FileLvl.FileRoot = FileRoot; OpTab_FileLvl.InfantAgeMonth = InfantAgeMonthsForTab; %add file root info and age info
        OpTab_FileLvl.NumSections = NumSectionsForTab; 
        
        OpTab_FileLvl(~ismember(OpTab_FileLvl.InfantAgeMonth,AgeMonth),:) = []; %remove rows that are not ages 3, 6, 9, or 18 mo

        ByAgeAndVocType_NumOrDur_Tab = GetTabwTotNumsOrDurByAgeandVocType(OpTab_FileLvl,AgeMonth); %get the file level numbers organised into total voc nums by age and voc type
        ByVocType_NumOrDur_Tab = GetTabwTotNumsOrDurByVocType(ByAgeAndVocType_NumOrDur_Tab, AgeMonth); %get total voc nums by voc type
        ByAge_NumOrDur_Tab = GetTabwTotNumsByAge(ByAgeAndVocType_NumOrDur_Tab, AgeMonth); %get tot voc nums by age
    end

    %-----------------------------------------------------------------------------------------------------------
    % This function gets the total duration/number of vocs by age and voc type
    % 
    % Inputs: - OpTab_FileLvl: table with total number/duration of voc or annotation type breakdown as well as file name root and infant age.
    %         - AgeMonth: vector of unique ages (3, 6, 9, 18 mo)
    % 
    % Outputs: - ByAgeAndVocTypeNumsTab: table with tot vocs number/duration by age and vocalisation type (at different levels, so this would include CHN/AN levl, 
    %                                          CHNSP/CHNNSP/AN level and if applicable, annotation tag level)
    function ByAgeAndVocType_NumsOrDur_Tab = GetTabwTotNumsOrDurByAgeandVocType(OpTab_FileLvl,AgeMonth)
    
        AgeMonthFromIpTab = unique(OpTab_FileLvl.InfantAgeMonth); %get unique ages from age column from input table
        if ~isequal(AgeMonthFromIpTab, AgeMonth) %make sure ages extracted from input table is same as the age vector we know from data
            error('Ages from table are not as expected from data')
        end
    
        %get table with total number of vocs by age and voc type
        for i = 1:numel(AgeMonth) %Go through ages
            %subset table for age; the last three columns are total numbers or duration, filename, age, and number of sections, so can remove that
            Age_i_Tab = OpTab_FileLvl(OpTab_FileLvl.InfantAgeMonth == AgeMonth(i),1:end-4); 
            Age_i_Tab = sum(Age_i_Tab); %get sum of vocs in each column
            Age_i_TabVarNames = Age_i_Tab.Properties.VariableNames; %get variable names of the table
    
            if ~isempty(Age_i_TabVarNames(contains(Age_i_TabVarNames,'_X'))) %if the table variable names contain the string '_X', then we know this is human-annotated data
                H_Annots = {'C','X','R','L','T','U','N',}'; %get vector for annoptation tags
                SpkrLvlLabels = {'CHNSP','CHNSP','CHNNSP','CHNNSP','AN','AN','AN'}'; %get corresponding vector for speaker level label;s
                ANOrCHNLabels = {'CHN','CHN','CHN','CHN','AN','AN','AN'}'; %get vectors for AN and CHN labels
                Totals = GetNumOrDurVocsByTypeForLowestLvlLabels(Age_i_Tab,Age_i_TabVarNames,H_Annots); %Get total number of vocs for each label type at the lowest level of labels
                AgeBlock = AgeMonth(i)*ones(numel(H_Annots),1); %assign age vector
                Age_i_OpTab{i} = table(AgeBlock,ANOrCHNLabels,SpkrLvlLabels,H_Annots,Totals); %pu together table
            else                
                SpkrLvlLabels = {'CHNSP','CHNNSP','AN'}'; %get vector for speaker level label;s
                ANOrCHNLabels = {'CHN','CHN','AN'}'; %get vectors for AN and 
                Totals = GetNumOrDurVocsByTypeForLowestLvlLabels(Age_i_Tab,Age_i_TabVarNames,SpkrLvlLabels);
                AgeBlock = AgeMonth(i)*ones(numel(SpkrLvlLabels),1);
                Age_i_OpTab{i} = table(AgeBlock,ANOrCHNLabels,SpkrLvlLabels,Totals);
            end
        end
    
        ByAgeAndVocType_NumsOrDur_Tab = Age_i_OpTab{1}; %assign first element of the cell array to a table
        for i = 2:numel(Age_i_OpTab) %then plop the rest into the existing table for full output
            ByAgeAndVocType_NumsOrDur_Tab = [ByAgeAndVocType_NumsOrDur_Tab; Age_i_OpTab{i}];
        end
    end
    
    %-----------------------------------------------------------------------------------------------------------
    % This function takes in a table with tot voc nums (or duration) for all files for a given age and gets the total number (or duration) of vocs across the input table, for the 
    % lowest level of voc type labels. For LENA labelled data, these labels would be CHNSP, CHNNSP, and AN, while for human-annotators, these would be the annotation tags 
    % (T, U, N, C, X, R, L). Note that while intended for the lowest label level (which means the labels cannot be split into sub-categories), it can be adapted to work for any 
    % level of labels.
    %
    %Inputs: Table wiith relevant file level totals for a given age (IpTab), variable names of this table (IpTabVarNames), and the set of labels we want to get the total 
    %       voc nums (or duration) extracted for that are all at the same level of labelling and are exhaustive at that level (eg. {CHNSP, CHNNSP, AN} is 
    %        acceptable while {CHNSP, AN} or {T, U, CHN} are not (LowestLvlLabels). 
    %
    %Output: vector with total numbers for each label in LowestLvlLabels (TotVocNums)
    function TotVocNumsOrDur = GetNumOrDurVocsByTypeForLowestLvlLabels(IpTab,IpTabVarNames,LowestLvlLabels)
        for k = 1:numel(LowestLvlLabels) %go through variable names
            ReqVar = IpTabVarNames(contains(IpTabVarNames,strcat('_',LowestLvlLabels{k}))); %pick out the variable of interest by matching against col names of the input table
            TotVocNumsOrDur(k,1) = IpTab.(ReqVar{1}); %pick out the relevant sum
        end
    end
    
    %-----------------------------------------------------------------------------------------------------------
    %This function recasts the total voc number by voc type and age table into tvoc number totals by voc type table.
    %
    %Inputs: table (IpTab) with total number of voc types and age block across the whole relevant dataset (DataType; eg. Lday, L5min, H5min-AllAd). The function below is written
    % with ByAgeAndVocType_NumOrDur_Tab (output in the function GetTotNumsOrDurOpTabs above) as the intended input.
    %
    %Output: table with tot voc counts with levels of labels
    function OpTab_ByVocType = GetTabwTotNumsOrDurByVocType(IpTab, AgeMonth)
    
        OpTabTemp_ByVocType = IpTab(IpTab.AgeBlock == AgeMonth(1),:); %assign sub-table for first age to a temp table
        for i = 2:numel(AgeMonth)
            CurrAgeBlockTab = IpTab(IpTab.AgeBlock == AgeMonth(i),:); %get sub-table for ith age
            OpTabTemp_ByVocType.Totals = OpTabTemp_ByVocType.Totals + CurrAgeBlockTab.Totals; %add up voc num totals
        end
    
        OpTab_ByVocType = removevars(OpTabTemp_ByVocType,'AgeBlock'); %assign to output after removing AgeBlock column
    end
    
    %-----------------------------------------------------------------------------------------------------------
    %This function recasts the total voc number by voc type and age table into voc number totals by age table.
    %
    %Inputs: table (IpTab) with total number of voc types and age block across the whole relevant dataset (DataType; eg. Lday, L5min, H5min-AllAd). The function below is written
    % with ByAgeAndVocType_NumOrDur_Tab (output in the function GetTotNumsOrDurOpTabs above) as the intended input.
    %
    %Output: table with tot voc counts for each age
    function OpTab_ByAge = GetTabwTotNumsByAge(IpTab, AgeMonth)
        for i = 1:numel(AgeMonth) %get total number of vocs by age only by going through ages and summing the total voc nums for each age block
            TotsByAge(i,1) = sum(IpTab.Totals(IpTab.AgeBlock == AgeMonth(i))); %
        end
        OpTab_ByAge = table(AgeMonth,TotsByAge); %make table for age
    end
end
