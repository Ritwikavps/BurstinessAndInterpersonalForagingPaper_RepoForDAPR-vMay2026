clear; clc

%This script summarises the number of 0 IEI merges by voc type and data type as well as info about number of vocs chained in merges and the number of merges with each chain length.
% One merge, as counted here, results in one merged voc from n unmerged vocs. Note that this is different from the summarised tables outputed as part of the merge process 
% (ZeroIviMergeDetailsTab_<DataType>.csv), which simply counts the total number of merge events. So, any 2 vocs getting merged is 1 merge event. So, if a merged voc is from 4 
% unmerged vocs, that would be counted as 3 merge events re: numbers in the merge count files in the metadata files.
% 
% Merge chains, as defined here, is when more than 2 vocs are merged into one. We output a vector containing the number of vocs in each such merge chain, for each merge chain event.
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLEASE CHANGE PATHS AND STRINGS IN FUNCTION CALL APPROPRIATELY
BasePath = '~/BaseDataPath/Data/';

%Get metadata files with by-file info about merge events (where one merge event is when 2 vocs are merged, so a chain of 4 vocs getting merged into 1 final voc would have 3 merge events).
cd(strcat(BasePath,'MetadataFiles/'));
MetadataStr = {'_LENA.csv','_LENA5min.csv','_HumAllANUtts.csv','_HumChildDirANOnly.csv'}; %list of strings for each data type, in order of Lday, L5min, H All Ad, H T-Ad
%Loop through and get respective metadata files in a cell array.
for i = 1:numel(MetadataStr)
    opts = detectImportOptions(strcat('ZeroIviMergeDetailsTab',MetadataStr{i})); %make sure to read in infant code as string
    opts = setvartype(opts, 'InfantID', 'string');
    MergesMetadataFile{i} = readtable(strcat('ZeroIviMergeDetailsTab',MetadataStr{i}),opts);
end

%Read metadata file foe LENA daylong data. This is because the merge metadata files only have ID and age and not file name, so gotta match file names from reading time series tables
% to infant age and ID using this metadata file. 
cd(strcat(BasePath,'MetadataFiles/'));
opts = detectImportOptions('MergedTSAcousticsMetadata.csv'); %make sure to read in infant code as string
opts = setvartype(opts, 'InfantID', 'string');
MetadataTab = readtable('MergedTSAcousticsMetadata.csv',opts);

%Consolidate path lists, and strings to read files from paths
UnmergedPathStrs = {'LENAData/A7_ZscoredTSAcousticsLENA/';
                    'HUMLabelData/A2_HUMLabelData_PostCleanUp/A8_MatchedLENAZscoreSections/';
                    'HUMLabelData/A2_HUMLabelData_PostCleanUp/A7_HlabelTS_Zscored/';
                    'HUMLabelData/A2_HUMLabelData_PostCleanUp/A7_HlabelTS_Zscored/'}; %strings to get to unmergedp files ath
UnmergedFileStr = {'*_ZscoredAcousticsTS_LENA.csv';
                   '*_MatchedLENA_ZscoreTS.csv';
                   '*_ZscoredAcousticsTS_Hum.csv';
                   '*_ZscoredAcousticsTS_Hum.csv'};%strings to read in files from unmerged paths
MergedPathStrs = {'LENAData/A8_NoAcoustics_0IviMerged_LENA'; 
                  'HUMLabelData/A2_HUMLabelData_PostCleanUp/A10_NoAcoustics_0IviMerged_L5min/';
                  'HUMLabelData/A2_HUMLabelData_PostCleanUp/A9_NoAcoustics_0IviMerged_Hum/';
                  'HUMLabelData/A2_HUMLabelData_PostCleanUp/A11_NoAcoustics_0IviMerged_Hum_ChildDirANOnly'}; %strings to get to merged files paths
MergedFileStr = {'*_NoAcoustics_0IviMerged_LENA.csv';
                 '*_NoAcoustics_0IviMerged_LENA5min.csv';
                 '*_NoAcoustics_0IviMerged_Hum.csv';
                 '*_NoAcoustics_0IviMerged_ChildDirANOnly_Hum.csv'}; %strings to read in files from merged path

%other input lists for GetNumVocsMerged function
AnType = {'_','_','All','ChnDir'}; %list of AnType inputs for the function; only applicable for child-directed adult human labeled data
AN_AnnotListToExclude = {[],[],[],{'U','N'}}; %list of inputs to suggest list of adult annotations to exclude; only applicable for child-directed adult human labeled data

%go through and do merge checks for each dataset
for i = 1:numel(UnmergedPathStrs)

    %Get list of unmerged files
    UnmergedPath = strcat(BasePath,UnmergedPathStrs{i});
    cd(UnmergedPath);
    UnmergedFiles = dir(UnmergedFileStr{i});

    %Get list of merged files
    MergedPath = strcat(BasePath,MergedPathStrs{i});
    cd(MergedPath);
    MergedFiles = dir(MergedFileStr{i});

    [NumVocsMergeChainVec{i},TotalMergeCt{i}] = GetNumVocsMerged(MergedFiles,UnmergedFiles,AnType{i},AN_AnnotListToExclude{i},MergesMetadataFile{i},MetadataTab);
end

%get table with merge counts
TotMergeCts_Tab = array2table(cell2mat(TotalMergeCt)'); %cell 2 mat
TotMergeCts_Tab.Properties.VariableNames = {'CHNSP','CHNNSP','AN'}; %add col names
DataType = {'Lday','L5min','H_AllAd','H_T_Ad'}'; %data type vector
DT_Tab = table(DataType); %make table out of that
TotMergeCts_Tab = [DT_Tab TotMergeCts_Tab]; %add to table

%CHECKS, once again. This time, we check to make sure that the number of merges resulting in one final merged vocs matches with the number of voc merge events, after correcting for voc merge 
% chains, for the subset of daylong data that is at 3, 6, 9 or 18 months.
for i = 1:height(TotMergeCts_Tab) %go through merge totals tab
    RelMergeMetadataTab = MergesMetadataFile{i}; %get relevant merge event counts table
    RelMergeMetadataTab = RelMergeMetadataTab(ismember(RelMergeMetadataTab.InfantAgeMonth,[3 6 9 18]),:); %subset for age blocks

    %get total number of voc merge events from the TotMergeCts_Tab for each voc type by correcting using number of vocs in voc merge chains.
    % Below the total number of merge events (where 2 vocs merge to form one) is simply the sum of the number of such events from voc merge chains of more than 2 vocs merging to 
    % form one voc, and the number of such events from voc merges involving only two vocs. The number of merge events from voc merge chains involving n vocs (n > 2) is 
    % [sum(NumVocsMergeChainVec{appropriate indexing} - 1)]. This is because the NumVocsMergeChainVec cell array contains vectors that lists the number of vocs involved in 
    % each voc merge chain inviolving n > 2 vocs for each dataset and speaker label (ergo the need for appropriate indexing).
    % The number of voc merge events coming from merges of two vocs merging into one is encoded in the TotMergeCts_Tab for each speaker label and dataset type. Of these, 
    % numel(NumVocsMergeChainVec{approrpiate indexing}) corresponds to the number of voc merge chains for num_vocs > 2. 
    % Therefore, [TotMergeCts_Tab_<approrpriate indexing> - numel(NumVocsMergeChainVec{approrpiate indexing})] gives the number of voc merge events coming from merges of 
    % two vocs, and this [- numel(NumVocsMergeChainVec{approrpiate indexing})] term is where the second -1 in the expressions below come from, forming -2 in the second term.
    Tots_CHNSP = TotMergeCts_Tab.CHNSP(i) + sum(NumVocsMergeChainVec{i}{1} -2); 
    Tots_CHNNSP = TotMergeCts_Tab.CHNNSP(i) + sum(NumVocsMergeChainVec{i}{2} -2);
    Tots_AN = TotMergeCts_Tab.AN(i) + sum(NumVocsMergeChainVec{i}{3} -2);

    %CHECK
    if (Tots_CHNSP ~= sum(RelMergeMetadataTab.TotalMergeCt_CHNSP)) || (Tots_CHNNSP ~= sum(RelMergeMetadataTab.TotalMergeCt_CHNNSP))...
            || (Tots_AN ~= sum(RelMergeMetadataTab.TotalMergeCt_AN))
        error(['Numver of voc merge events (from table with by-file numbers) do not match with number of voc merge events computed from number of times 2 or more vocs were merged into one' ...
            'and appropriate corrections based on number of vocs in voc merge events.'])
    end
end

%go to destination path and write table output
cd(strcat(BasePath,'MetadataFiles/'));
writetable(TotMergeCts_Tab,'TotNumMerges_NVocsTo1Voc_ByVocType_ReqAgesOnly.csv')
%-----------------------------------------------------------------------------------------------
%PLOTTING!!
%----------------------------------------------
%Summarising voc merge chains (we only do this for Lday and L5min data; human listener labeled data only has instances of 3 vocs in voc merge chains).
figure1 = figure('PaperType','<custom>','PaperSize',[19.5 9],'Color',[1 1 1]);

%axes positions, x tick values, and x axis limits
axesPos = [0.0797354497354495 0.148333333333334 0.385873015873015 0.815; 
           0.604194114455739 0.148333333333334 0.385873015873016 0.815];
XTix = {[3 5 10 15 20 25 30];
        [3 5 7 9 11]};
Xlims = [2.5 30.5;
        2.5 11.5];
XAxoffset = [-0.25 0 0.25];

%go through teh first two indices, corresponding to Lday and L5min
for i = 1:2
    
    %define axis
    axes_i = axes('Parent',figure1,'Position',axesPos(i,:)); hold(axes_i,'on');
    
    %go through the cell array: this has the the number of vocs that go into a merge chain for each instance of more than 2 vocs being merged. There are 3 cell arrays in here, the first for
    % CHNSP merges, the second for CHNNSP, the third for AN.
    for j = 1:numel(NumVocsMergeChainVec{i})
        CurrNumVec = NumVocsMergeChainVec{i}{j}; %get the jth merge chain vector for the ith data set
        [u_Nums,Y] = GetBarNumsToPlot_MergeChainCts(CurrNumVec); %get unique merge chain length and the number of instances for each
        %stem(u_Nums+XAxoffset(j),Y,'filled','LineStyle','-','LineWidth',1.5) %plot
        plot(u_Nums,Y,'Marker','.','MarkerSize',30,'LineStyle','-','LineWidth',1.5) %plot
    end

    ylabel({'Number of occurences'}); xlabel({'Number of vocalizations in a merge chain'});
    legend({'ChSp','ChNsp','Ad'})
    title(DataType{i})
    ylim(axes_i,[0.8 14000]); xlim(axes_i,Xlims(i,:)); hold(axes_i,'off');
    set(axes_i,'FontName','Helvetica Neue','FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorGrid','on','XMinorTick','on','XTick',...
        XTix{i},'YGrid','on','YLimitMethod','tight','YMinorTick','on','YScale','log','ZLimitMethod','tight');
end

%----------------------------------------------
%SUMMARY OPs
%----------------------------------------------
%output summaries for human listener labelled data
for i = 3:4 %go through indices corresponding to human listener data
    for j = 1:numel(NumVocsMergeChainVec{i}) %go through ith data type's vector with voc merge numbers
        CurrNumVec = NumVocsMergeChainVec{i}{j}; %get the current vector; the first is for CHNSP, second for CHNNSP, third for AN
        if ~isempty(CurrNumVec(CurrNumVec ~= 3)) %check to make sure that there are only instances of 3 voc long merge chains
            error('There are merge chains with lengths not equal to 3 vocs') %error message (to prompt adapting the code)
        end
        HumDataMergeChains_3Vocs{i-2}(j) = numel(CurrNumVec); %add number of 3 voc long merge chains for jth voc type and ith data set (but data set indexed as i-2)
    end
end

fprintf('Human listener-labeled data only has voc merge chains that are 3 vocs long. \n')
fprintf('Number of 3 voc long merge chains for human listener labelled data (%s) included are: \n CHNSP = %i \n CHNNSP = %i \n AN = %i \n', ...
           DataType{3},HumDataMergeChains_3Vocs{3-2}(1),HumDataMergeChains_3Vocs{3-2}(2),HumDataMergeChains_3Vocs{3-2}(3))
fprintf('Number of 3 voc long merge chains for human listener labelled data (%s) included are: \n CHNSP = %i \n CHNNSP = %i \n AN = %i \n', ...
           DataType{4},HumDataMergeChains_3Vocs{4-2}(1),HumDataMergeChains_3Vocs{4-2}(2),HumDataMergeChains_3Vocs{4-2}(3))



%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

% %Get counts of merges
% [NumVocsMergeChainVec_AllAN,TotalMergeCt_AllAN] = GetNumVocsMerged(MergedHfiles,UnmergedHfiles,'All',{'T','U','N'});
% [NumVocsMergeChainVec_Chdir,TotalMergeCt_Chdir] = GetNumVocsMerged(MergedHfiles_ChildDirANOnly,UnmergedHfiles,'ChnDir',{'U','N'});

% AN_VocClass = {'all','only child-directed'}; SpkrType = {'adult','infant sp-related','infat non-sp related'};  %adult voc class (all or child-directed only), and speaker type
% %Make array to pass to fprintf (output text)
% Sprintf_NumMat = [AnVocMergeCtr_AllAN, ChnspVocMergeCtr_AllAN, ChnnspVocMergeCtr_AllAN; %all AN
%                   AnVocMergeCtr_ChnDirAN, ChnspVocMergeCtr_ChnDirAN, ChnnspVocMergeCtr_ChnDirAN]; %Chn-directed AN only
% for i = 1:numel(SpkrType) %loop for output text
%     for j = 1:numel(AN_VocClass)
%         fprintf('The total # of %s voc mergers done where annotations are different when %s adult vocs are considered is %i \n',SpkrType{i},AN_VocClass{j},Sprintf_NumMat(j,i));
%     end
% end

%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%This function takes in list fo files where vocs of the same speake label separated by 0 IVIs have not been merged and outputs the total number of merges (TotalMergeCt) for a 
% and the number of vocs contributing to each voc merge chain. That is, if more than 2 vocs are merged at a time, that is a merge chain.
%
% Inputs: MergedFiles: list of files after 0 IVI merging
%       - UnmergedFiles: list of files before merging
%       - AnType: string identifying the adult voc type (all adult or child-directed adult only); only applicable to human labelled data
%       - AN_AnnotListToExclude: list of adult annotations to exclude for child-directed adult data. Only applicaqble to human labelled data
%       - MergesMetadatafile: metadatafile with info about number of merge events (where one merge event is a merge of two vocs into one. So, a merge of 4 vocs into one 
%                             would have three merge events) for the specific data type and by vocalisation type (CHNSP, CHNNSP, AN)
%       - MetadataTab: metadata table with metadata about the LENA day-long dataset. This is because the merge metadata files only have ID and age and not file name, so gotta 
%                      match file names from reading time series tables to infant age and ID using this metadata file.
% 
% Outputs: NumVocsMergeChainVec: Cell array with number of vocs in each voc merge chain (instances of more than 2 vocs merged into 1 voc), separately for CHNSP, CHNNSP, and AN,
%                                in that order
%        - TotalMergeCt: vector with total number of instances of n number of vocs merfed into one voc, separtely for CHNSP, CHNNSP, AN, in that order. Here, one merge results in
%                        one merged voc. 
function [NumVocsMergeChainVec,TotalMergeCt] = GetNumVocsMerged(Mergedfiles,Unmergedfiles,AnType,AN_AnnotListToExclude,MergesMetadataFile,MetadataTab)

    %Initialise numbers tracking merge counts for CHNSP, AN, CHNNSP; as well as vectors storing number of vocs in each instance of a voc merge chain
    TotalMergeCt_CHNSP = 0; NumVocsMergeChainVec_CHNSP = [];
    TotalMergeCt_CHNNSP = 0; NumVocsMergeChainVec_CHNNSP = [];
    TotalMergeCt_AN = 0; NumVocsMergeChainVec_AN = [];

    for i = 1:numel(Mergedfiles) %go through list of files

        %read in table with 0 Ivi merges and table pre-merge and process appropriately
        MergedTab = readtable(Mergedfiles(i).name); MergedTab = ProceesingOpsOnIpTab(MergedTab);
        UnmergedTab = readtable(Unmergedfiles(i).name);  UnmergedTab = ProceesingOpsOnIpTab(UnmergedTab); 

        %Checks: Get file name root to get metadata info from overall metadata file.
        FnRoot = Mergedfiles(i).name(1:11);
        MetadataLine = MetadataTab(contains(MetadataTab.FileNameRoot,FnRoot),:);
        AgeFrmMetaData = MetadataLine.InfantAgeMonth; %get age
        %IdFrmMetaData = regexprep(MetadataLine.InfantID{1},'0',''); %get ID and remove prefix zeros (to compare with infant ID from the merges metadata file)
        IdFrmMetaData = MetadataLine.InfantID{1};

        if ismember(AgeFrmMetaData,[3 6 9 18]) %ONLY proceed if age is part of the study
            %get correspondinh line from the merges metadata file.
            MergesMetadataLine = MergesMetadataFile(strcmp(MergesMetadataFile.InfantID,IdFrmMetaData) & MergesMetadataFile.InfantAgeMonth == AgeFrmMetaData,:);
    
            %Initialise merge counts and voc merge chain vectors for ith file (this is to check to make sure that everything works as intended). 
            TotMergeCts_ForChks = [0; 0; 0];
            NumVocsMergeChainVec_CHNSP_ForChks = []; NumVocsMergeChainVec_CHNNSP_ForChks = []; NumVocsMergeChainVec_AN_ForChks = []; 
            
            if strcmp(AnType,'ChnDir') %if we aren't considering all adult voc types
                UnmergedTab = UnmergedTab(~contains(UnmergedTab.Annotation,AN_AnnotListToExclude),:); %pick out child-directed adult vocs ONLY
                %Note that we don't have to do this for the merged tables because we do have all adult vocs and chil-directed adult vocs ONLY cases for the merged tables
            end
        
            if ~isequal(MergedTab,UnmergedTab) %if Merged and unmerged tables are not equal
                MergedLines = setdiff(MergedTab,UnmergedTab); UnmergedLines = setdiff(UnmergedTab,MergedTab); %get the set of merged and unmerged lines using setdiff.
                %The merged and unmerged tables will differ only for the vocs that have been merged, so setdiff both ways should pick these up.
    
                for j = 1:height(MergedLines) %go through the list of merged lines
                    %For each merged voc, get the corresponding set of unmerged vocs, where successive vocs are sepaarted by 0 Ivi. Make sure that we aren't picking unmerged vocs
                    % from differenct subrecs. 
                    UnmergedSubset = UnmergedLines(UnmergedLines.start >= MergedLines.start(j) & UnmergedLines.xEnd <= MergedLines.xEnd(j)...
                        & strcmp(UnmergedLines.FileNameUnMerged,MergedLines.FileNameUnMerged{j}) & (UnmergedLines.SectionNum == MergedLines.SectionNum(j)),:);
                    % UnmergedSubset
                    % MergedLines(j,:)
                    
                    if numel(unique(UnmergedSubset.speaker)) > 2 %if there is more than one speaker type, throw error
                        error('More than oen speaker type in the unmerged set of vocs corresponding to a merged voc')
                    end
    
                    Spkrtype = unique(UnmergedSubset.speaker); %get the uniquespeaker type
                        
                    switch Spkrtype{1} %increment counter type accordingly
                        case 'AN'
                            TotalMergeCt_AN = TotalMergeCt_AN + 1; %dataset level merge tracking
                            NumVocsMergeChainVec_AN = [NumVocsMergeChainVec_AN; height(UnmergedSubset)]; %dataset level merge chain voc numbers tracking
    
                            TotMergeCts_ForChks(3) = TotMergeCts_ForChks(3) + 1; %file level merge tracking for checks
                            NumVocsMergeChainVec_AN_ForChks = [NumVocsMergeChainVec_AN_ForChks height(UnmergedSubset)]; %file level merge chain voc numbers tracking for checks
                        case 'CHNSP'
                            TotalMergeCt_CHNSP = TotalMergeCt_CHNSP + 1;
                            NumVocsMergeChainVec_CHNSP = [NumVocsMergeChainVec_CHNSP; height(UnmergedSubset)];
    
                            TotMergeCts_ForChks(1) = TotMergeCts_ForChks(1) + 1;
                            NumVocsMergeChainVec_CHNSP_ForChks = [NumVocsMergeChainVec_CHNSP_ForChks height(UnmergedSubset)];
                        case 'CHNNSP'
                            TotalMergeCt_CHNNSP = TotalMergeCt_CHNNSP + 1;
                            NumVocsMergeChainVec_CHNNSP = [NumVocsMergeChainVec_CHNNSP; height(UnmergedSubset)];
    
                            TotMergeCts_ForChks(2) = TotMergeCts_ForChks(2) + 1;
                            NumVocsMergeChainVec_CHNNSP_ForChks = [NumVocsMergeChainVec_CHNNSP_ForChks height(UnmergedSubset)];
                    end
                end
            end
    
            % At this point, the NumVocsMergeChainVec lists all instances of n >= 2 vocs merging into 1 voc. That is, if 2 vocs are merged into one, that gets added to this vector
            % as 2; if 3 vocs get merged into one, that bets added to this vector as 3; then, if 10 vocs are merged into one, that gets added to this vector as 10, etc. So the vector
            % would look like [2 3 10 ....]. 
            % Now, if n >= 2 vocs are merged into 1 voc, there are n-1 merge events (m_e) going into it. However, this would get counted as one merge, resulting in one voc from n vocs.
            % So, for the vector [2 3 10] above, there will be 1 + 2 + 9 merge events, but 3 merges (M; one for each chain of n >= 2 vocs).
            % Thus, (the number of merge events in a chain, m_e = number of vocs going into the event - 1*M), where M is the number of merges where a merge is n >= 2 vocs merging into
            % one. At the file or dataset level, if we have the vector (NumVocsMergeChainVec) listing the number of vocs going into each voc merge, and the total number of merges (M)
            % for that label category, we can test that this computation has been done correctly by using numbers from the metadata file (ZeroIviMergeDetailsTab_<DataType>.csv) which
            % counts the number of merge events (m_e) for each file for each label type as m_e = sum(NumVocsMergeChainVec) - M. 
            AN_MergeNums = sum(NumVocsMergeChainVec_AN_ForChks) - TotMergeCts_ForChks(3);
            CHNSP_MergeNums =  sum(NumVocsMergeChainVec_CHNSP_ForChks) - TotMergeCts_ForChks(1);
            CHNNSP_MergeNums =  sum(NumVocsMergeChainVec_CHNNSP_ForChks) - TotMergeCts_ForChks(2);

            %check that the numbers match
            if AN_MergeNums ~= MergesMetadataLine.TotalMergeCt_AN
                Mergedfiles(i).name
                disp('AN')
            elseif CHNSP_MergeNums ~= MergesMetadataLine.TotalMergeCt_CHNSP
                Mergedfiles(i).name
                disp('CHNSP')
            elseif CHNNSP_MergeNums ~= MergesMetadataLine.TotalMergeCt_CHNNSP
                Mergedfiles(i).name
                disp('CHNNSP')
            end
        end
    end

    %remove voc merges with only 2 vocs in a merg. We want actual voc merge chains.
    NumVocsMergeChainVec_CHNSP = NumVocsMergeChainVec_CHNSP(NumVocsMergeChainVec_CHNSP > 2);
    NumVocsMergeChainVec_CHNNSP = NumVocsMergeChainVec_CHNNSP(NumVocsMergeChainVec_CHNNSP > 2);
    NumVocsMergeChainVec_AN = NumVocsMergeChainVec_AN(NumVocsMergeChainVec_AN > 2);

    %assign totals to output
    TotalMergeCt = [TotalMergeCt_CHNSP; TotalMergeCt_CHNNSP; TotalMergeCt_AN];
    NumVocsMergeChainVec = {NumVocsMergeChainVec_CHNSP; NumVocsMergeChainVec_CHNNSP; NumVocsMergeChainVec_AN};

end

%-------------------------------------------------------
%This function takes in an input table, remove unnecessary cols, changes FAN and MAN to AN
function [OpTab] = ProceesingOpsOnIpTab(IpTab)

    SecNumVec = IpTab.SectionNum; %get the section number column
    IpTab = IpTab(:,1:6); %remove unnecessary cols. The first 6 are the ones thar merged and unmerged files have in common.
    %But, for human listener labelled data, this removes the section number column, so we put it back below.
    IpTabVarNames = IpTab.Properties.VariableNames; %gat variable names 
    if isempty(IpTabVarNames(contains(IpTabVarNames,'SectionNum'))) %if there is no section number vector, add it bacl
        IpTab.SectionNum = SecNumVec;
    end
    IpTab.speaker(contains(IpTab.speaker,'AN')) = {'AN'}; %chane instances of FAN and MAN to AN

    OpTab = IpTab;
end

%-------------------------------------------------------
function [u_Nums,Y] = GetBarNumsToPlot_MergeChainCts(CurrNumVec)
    u_Nums = unique(CurrNumVec);
    for i = 1:numel(u_Nums)
        Y(i) = numel(CurrNumVec(CurrNumVec == u_Nums(i)));
    end
end





















    


% function [NumVocsMergeChainVec,TotalMergeCt] = GetNumVocsMerged(InputTab,VocType)
% 
%     InputTabVarNames = InputTab.Properties.VariableNames;
%     if isempty(InputTabVarNames(contains(InputTabVarNames,'SectionNum'))) %if there is NO column with section num info
%         InputTab.SectionNum = GetSectionNumVec(InputTab); %get section number information, and add section number information to InputTab
%     end
% 
%     InputTab.speaker(contains(InputTab.speaker,'AN')) = {'AN'}; %change FAN and MAN to a single AN type, since we are merging all AN types with 0 Ivi into one voc         
%     InputTab_AcousRemoved = removevars(InputTab,{'logf0_z','dB_z','logDur_z'}); %First, remove acoustics from the table
% 
%     u_SecNum = unique(InputTab_AcousRemoved.SectionNum); %get unique section numbers
%     u_Spkr = unique(InputTab_AcousRemoved.speaker); %types of speakers
% 
%     SpkrSubTab = InputTab(contains(InputTab.speaker,VocType),:); %subset for speaker label
% 
%     NumVocsMergeChainVec = []; TotalMergeCt = 0; %Initialise NumVocsMergeChainVec vector and the total number of merges for the file for this speake type  
% 
%     while true  %infinite while loop; this one is to go through the input table row by row
% 
%         NumVocsMergeChain = 1; %Initialise number to track current voc merge chain, if any. So, the default is 1, because one merge = 2 vocs, and then as the merge chain lengthens,
%         % we keep tracking how many vocs go into this. So, for a merge with 2 vocs, this will get incremented to 2, for a merge with 3 vocs, this will get incremented to 3, etc.
% 
%         %Checks: if table is empty or only has one voc in it, break.
%         if (isempty(SpkrSubTab)) || (numel(SpkrSubTab.start) == 1)
%             break
%         end
% 
%         CurrInd = 1; %start at the 1st voc in the table
%         NewLine = SpkrSubTab(CurrInd,:); %get the current line
% 
%         while true %infinite while loop; this one is to keep track of the current chain of vocs being merged, if applicable
%             if SpkrSubTab.start(CurrInd+1)-NewLine.xEnd <= 0 %check if the Ivi for the end of the ith voc and the start of the (i+1)th voc is 0. We
%                 %this value as IviMergeTol (See towards the beginning of this function)
%                 CurrInd = CurrInd + 1; %if yes, update CurrInd
%                 NewLine.xEnd = SpkrSubTab.xEnd(CurrInd); %and update the end time of the ith voc with the end time of the (i+1)th voc
%                 TotalMergeCt = TotalMergeCt + 1; %one merge has been performed; update merge count
%                 NumVocsMergeChain = NumVocsMergeChain + 1;
%                 if CurrInd == numel(SpkrSubTab.start) %if the updated CurrInd = number fo rows in the table, break
%                     break
%                 end
%             else %if ith and (i+1)th vocs are separated by greater than 0 s IVI, we need to break. But first, we much check if there is a chain of voc merges with more than 2 vocs
%                 % involved. And this check need only happen at the end of a voc merge chain, taht is, when 2 vocs are no longer separated by 0 s IVI. 
%                 if NumVocsMergeChain > 2 %if the chain has more than 2 vocs
%                     NumVocsMergeChainVec = [NumVocsMergeChainVec; NumVocsMergeChain]; %add the chain info (number of vocs involved) to the vector tracking it
%                     SpkrSubTab(1:CurrInd,:) %display the set of vocs in merge
%                 end
%                 break %break
%             end
%         end
% 
%         SpkrSubTab(1:CurrInd,:) = []; %remove rows till this point from input table
%     end
% end