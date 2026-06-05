% @authorinfo, Dec 2025

% This function computes the burstiness measure at the daylong recording level (or file level, for validation data), by pooling IEIs across multiple subrecs or 5-min subsections
% where applicable. Note the the IEI calculation is done such that IEIs are not computed between vocs from different subrecs or 5-min sections.
% (written as part of paper revision).
% Inputs: - ZscoreDir: directory with .csv files (time series)
%         - StringToRemoveFromFname: string to remove from file name to the file name root
%         - SpkrType: speaker type vector (e.g., {'CHNSP','AN','CHNNSP'}, not necessarily in that order)
%         - MetadataTab: table with metadata for time series data
% 
% Output: - OpTab: table with burstiness measure and other details.
function OpTab = RevFn_GetIEI_BurstinessQt(ZscoreDir,StringToRemoveFromFname,SpkrType,MetadataTab)

    Ctr = 0; %Initialise counter variable (because we are stacking burstiness measures for CHNSP, CHNNSP, and AN in a column instead of making sepaarte columns

    for i_dir = 1:numel(ZscoreDir) %go through list of files

        ZscoreFnRoot = erase(ZscoreDir(i_dir).name, StringToRemoveFromFname); % get the root of the filename

        CurrInfID = MetadataTab.InfantID(contains(MetadataTab.FileNameRoot,ZscoreFnRoot)); %get infant id, and age in days and months
        CurrAgeDays = MetadataTab.InfantAgeDays(contains(MetadataTab.FileNameRoot,ZscoreFnRoot));
        CurrAgeMonths = MetadataTab.InfantAgeMonth(contains(MetadataTab.FileNameRoot,ZscoreFnRoot));
 
        ZscoreTab = readtable(ZscoreDir(i_dir).name,'Delimiter',','); %read in table

        for i_spkr = 1:numel(SpkrType) %go through speaker type list

            Ctr = Ctr + 1; %Update Ctr
            SpkrTab = ZscoreTab(strcmp(ZscoreTab.speaker,SpkrType{i_spkr}),:); %subset for speaker type
            u_SectionNum = unique(SpkrTab.SectionNum); %get unique section numbers

            IEIVecForBurstiness = []; %initialise empty vector to store IEIs
    
            for i_sec = 1:numel(u_SectionNum) %go through unique section numbers (so we don't compute IEIs across different subrecs or 5-min sections)
 
                SubTab = SpkrTab(SpkrTab.SectionNum == u_SectionNum(i_sec),:); %subset for section number

                if height(SubTab) > 1 %make sure that there are at least 2 vocs so there is at least one IEI
        
                    %Error check: there should only be one unmerged file name
                    if numel(unique(SubTab.FileNameUnMerged)) ~= 1
                        error('There should be only 1 unmerged file name')
                    end
        
                    CurrIeis = SubTab.start(2:end) - SubTab.xEnd(1:end-1); %get IEIs
                   
                    %Check if there are NaN IEIs
                    if numel(CurrIeis) ~= numel(CurrIeis(~isnan(CurrIeis)))
                        warning('There are some NaN IEIs')
                    end

                    IEIVecForBurstiness = [IEIVecForBurstiness; CurrIeis]; %add to recording/file-level vector
                end 
            end 

            %calculate burstiness measure
            if numel(IEIVecForBurstiness) >= 10 %only if there are at least 10 IEIs total at the recording day/validation data file-level
                BurstinessNum = (std(IEIVecForBurstiness,'omitnan') - mean(IEIVecForBurstiness,'omitnan'));
                BurstinessDenom = (std(IEIVecForBurstiness,'omitnan') + mean(IEIVecForBurstiness,'omitnan'));
                BurstinessQt(Ctr,1) = BurstinessNum/BurstinessDenom;

                if (BurstinessQt(Ctr,1) == -1) || (isnan(BurstinessQt(Ctr,1)))
                    disp('Burstiness measure is -1 or NaN, this should not happen. Check the number of IEIs and what those IEIs look like.')
                end
            else
                BurstinessQt(Ctr,1) = NaN; %if there are fewer than 10 IEIs
            end

            %Get all other columns for output table
            InfantID{Ctr,1} = CurrInfID;
            InfantAgeDays(Ctr,1) = CurrAgeDays;
            InfantAgeMonths(Ctr,1) = CurrAgeMonths;
            NumIeis(Ctr,1) = numel(IEIVecForBurstiness);
            FileNameRoot{Ctr,1} = ZscoreFnRoot;
            SpeakerType{Ctr,1} = SpkrType{i_spkr};
        end
    end

    OpTab = table(BurstinessQt,SpeakerType,InfantID,InfantAgeDays,InfantAgeMonths,NumIeis,FileNameRoot);
end