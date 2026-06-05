function [OpTab] = GetRogueInfOrAdultAnnotsInOtherTiers(CsvDir,CsvFnRootSuffix)

    %%@author info, Apr 2022; modified Nov 2023
    % Code to test if there are annotations that should have been in Adult utt dir or Infant Voc Type are in other tiers

    %inputs: -CsvDir (list of csv files parsed from eaf files)
            %-CsvFnRootSuffix (suffix or extension substring to delete from csv file name to get the file name root)
    
    %list of annotations for adult and infant tier
    AdultAnnots = {'T','U','N'};
    InfantAnnots = {'C','R','X','L'};
    
    for ii = 1:numel(CsvDir)
         CsvTab = readtable(CsvDir(ii).name,'Delimiter',','); %read csv file
    
         %add file name as a column to the table
         FileNameVec = cell(size(CsvTab,1),1);  %get empty file name cell array (because the file name is a string, this has to be a cell array)
         [FileNameVec{:}] = deal(erase(CsvDir(ii).name,CsvFnRootSuffix));
         FileNameTab = table(FileNameVec); %convert to table
         CsvTab = [CsvTab FileNameTab]; %add file name table (with one column) to CsvTab
    
         UniqueTiersInFile = unique(CsvTab.TierTypeVec); %find unique tier names
    
         if ii == 1 %initialise Output table
             OpTab = array2table(zeros(0,size(CsvTab,2)));
             OpTab.Properties.VariableNames = CsvTab.Properties.VariableNames;
         end
    
         OpTab = [OpTab; GetRowsWithRogueAnnots(CsvTab,'Adult Utterance Dir',AdultAnnots,UniqueTiersInFile)]; %add to output table; for details, see user-defined function at the end
         OpTab = [OpTab; GetRowsWithRogueAnnots(CsvTab,'Infant Voc Type',InfantAnnots,UniqueTiersInFile)];
    
    end
    
    %Note that Tier 'Label' has annotation 'L'; and tier 'Recast' has
    %annottaion 'R'; So these need to be filtered
    LabelTab = OpTab(strcmpi(OpTab.TierTypeVec,'Label'),:);
    RecastTab = OpTab(strcmpi(OpTab.TierTypeVec,'Recast'),:);
    
    %get all unique annotations in Label tier and Recast tier
    LabelAnnot = lower(unique(strtrim(LabelTab.Annotation)));
    RecastAnnot = lower(unique(strtrim(RecastTab.Annotation)));
    
    %Check if Label is all L; and if Recast is all R. If yes, remove those tiers flagged
    if (strcmp(LabelAnnot,'l')) && (strcmp(RecastAnnot,'r'))
        OpTab = OpTab(~contains(OpTab.TierTypeVec,{'Label','Recast'},'IgnoreCase',true),:);
    end

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    %Internal function to flag and output (as a single table) as instances of Infant Voc Type annotatuons (R,X,C,L) and Adult Utt Dir (T,U,N) annotations being in
    %other tiers  
    function [TempOpTab] = GetRowsWithRogueAnnots(CsvTab,DesiredTierName,DesiredAnnotList,UniqueTiersInFile)
    
        TempOpTab = array2table(zeros(0,size(CsvTab,2))); %make emprty array with same number of cols as CsvTab
        TempOpTab.Properties.VariableNames = CsvTab.Properties.VariableNames;
    
        TiersToCheck = UniqueTiersInFile(~contains(UniqueTiersInFile,DesiredTierName,'IgnoreCase',true)); %pick out tier names that are in the file (listed in cell array UniqueTiersInFile) excluding the
        %tier name we are checking (DesiredTierName). So, if we want to see if any T, U, or N annots are present in any tiers other than adult utt
        %dir, DesiredTierName = 'Adult Utterance Dir'
    
        %Go through each tier name
        for i = 1:numel(TiersToCheck)
    
            SubTab = CsvTab(contains(CsvTab.TierTypeVec,TiersToCheck{i},'IgnoreCase',true),:); %subset table for current tier ONLY
    
            for j = 1:numel(DesiredAnnotList)
                TempOpTab = [TempOpTab; SubTab(strcmpi(strtrim(SubTab.Annotation),DesiredAnnotList{j}),:)]; %add to op tab if there are any annotations belonging to the 
                % adult utt dir tier or the infant voc type tier, as specified by the DesiredTierName variable
            end
        end
    end
end