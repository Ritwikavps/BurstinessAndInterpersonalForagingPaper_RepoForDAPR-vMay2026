function [TSOnlyTab_IviProcessed, TotalMergeCt_AN,TotalMergeCt_CHNSP,TotalMergeCt_CHNNSP] = MergeZeroIviVocsAndGetTSOnlyTab(InputTab)

    %April 2024
    %This function takes the input table with speaker labels, vocalisation time series (start and end times), acoustics, etc, removes the acoustics (since the current study only looks at 
    %IVIs), and then joins any consecutive vocs of the same speaker type that have a zero IVI between them. So, if two CHNSP (or CHNNSP or AN) vocs follow one after the other, with IVI = 0,
    % then this function joins them together.

    %Input: InputTab; input data atble
    %Outputs: - TSOnlyTab_IviProcessed; output table with acoustics info removed + with 0 IVI consecutive vocs of teh same speaker type (note that we treat adult speakers MAN and FAN as
                % one single speaker type.
             %- TotalMergeCt_AN,TotalMergeCt_CHNSP,TotalMergeCt_CHNNSP; the total number of voc merges done, for each speaker type.
    
    %get section number info if applicable
    InputTabVarNames = InputTab.Properties.VariableNames;
    if isempty(InputTabVarNames(contains(InputTabVarNames,'SectionNum'))) %if there is NO column with section num info
        InputTab.SectionNum = GetSectionNumVec(InputTab); %get section number information, and add section number information to InputTab
    end
    
    InputTab.speaker(contains(InputTab.speaker,'AN')) = {'AN'}; %change FAN and MAN to a single AN type, since we are merging all AN types with 0 Ivi into one voc         
    InputTab_AcousRemoved = removevars(InputTab,{'logf0_z','dB_z','logDur_z'}); %First, remove acoustics from the table

    u_SecNum = unique(InputTab_AcousRemoved.SectionNum); %get unique section numbers
    u_Spkr = unique(InputTab_AcousRemoved.speaker); %types of speakers
    TotalMergeCt_AN = 0; %initialise merge cts acrosss sections for diff speaker types
    TotalMergeCt_CHNSP = 0;
    TotalMergeCt_CHNNSP = 0;

    TSOnlyTab_IviProcessed = array2table(zeros(0,size(InputTab_AcousRemoved,2))); %initialise table to save output table after processing for 0 IVI vocs, for each secton
    TSOnlyTab_IviProcessed.Properties.VariableNames = InputTab_AcousRemoved.Properties.VariableNames; %set variable names

    for j = 1:numel(u_SecNum)

        Section_MergedTab = array2table(zeros(0,size(InputTab_AcousRemoved,2))); %initialise table to save output table after processing for 0 IVI vocs, for each speaker, in this section
        Section_MergedTab.Properties.VariableNames = InputTab_AcousRemoved.Properties.VariableNames; %set variable names
        
        SecSubTab = InputTab_AcousRemoved(InputTab_AcousRemoved.SectionNum == u_SecNum(j),:); %pick out each unique section

        for k = 1:numel(u_Spkr) %go through speaker labels
            SpkrSubTab = SecSubTab(contains(SecSubTab.speaker,u_Spkr{k}),:); %subset for speaker type
            if ~isempty(SpkrSubTab) %proceed if the subsetted table is not empty
                [MergedTabForSpkr,TotalMergeCt_Temp] = MergeZeroIviVocs(SpkrSubTab); %get output table for processing for vocs separated by 0 IVI, as well as the total merge count
    
                Section_MergedTab = [Section_MergedTab; MergedTabForSpkr]; %add to table to store processed table for thsi section
                if strcmp(u_Spkr{k},'AN')
                    TotalMergeCt_AN = TotalMergeCt_AN + TotalMergeCt_Temp; %update number of merges
                elseif strcmp(u_Spkr{k},'CHNSP')
                    TotalMergeCt_CHNSP = TotalMergeCt_CHNSP + TotalMergeCt_Temp;
                elseif strcmp(u_Spkr{k},'CHNNSP')
                    TotalMergeCt_CHNNSP = TotalMergeCt_CHNNSP + TotalMergeCt_Temp;
                end
            end
        end

        Section_MergedTab = sortrows(Section_MergedTab,'start'); %sort by start time (do this at the section level)
        TSOnlyTab_IviProcessed = [TSOnlyTab_IviProcessed; Section_MergedTab]; %add the processed table for this section to the final output tab
    end
%------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function [MergedTabForSpkr,TotalMergeCt] = MergeZeroIviVocs(SpkrSubTab)    

        %This function takes the subsetted table for a given speaker type (CHNSP, CHNNSP, or AN), and merges all vocs that have 0 IVI between them. This includes multiple vocs that
        % are chained together with consecutive 0 IVIs. Note that we do this separately for each different section in the data. Also note that we treat FAN and MAN as a singel adult
        % speaker type.

        %Input: - SpkrSubTab: subsetted table for each speaker type for that section.
        %Outputs: - MergedTabForSpkr: the table after all necessary merges have been done
                % - TotalMergeCt: the total number of voc merges that have been performed.

        MergedTabForSpkr = array2table(zeros(0,size(SpkrSubTab,2))); %initialise table to save input table row by row, after processing for 0 IVI vocs
        MergedTabForSpkr.Properties.VariableNames = SpkrSubTab.Properties.VariableNames; %set variable names

        TotalMergeCt = 0; %initialise variable to keep track of total number of voc merges performed
        IviMergeTol = 0; %if vocs of the same type are separated by 0 s IVI, we merge 'em

        while true  %infinite while loop; this one is to go through the input table row by row
            %The algorithm is as follows: 1. Start at the 1st row in input table (using intialised CurrInd = 1 and NewLine variable, which gets written into output table)
                                         %2. Check if this is the last row in the table. If yes, add this row to output table and break.
                                         %3. Check if Ivi for current voc and next voc is zero. 
                                            % 3a. If yes, update CurrInd by 1, and update end time of current voc as end time of the next voc. Now, the NewLine is such that the 
                                                % start time is from the ith voc and the end time is from the (i+1)th voc, because the IVI between these two vocs is zero. 
                                            % 3b. Update total number of voc merges performed. 
                                            % 3c. Repeat step 3 (and sub-steps) with the updated end time and the start of the next voc in the input table (by updating CurrInd), 
                                                % till Ivi is not zero. 
                                            % 3d. Break once Ivi is not zero. 
                                          %4. Write (updated, if applicable) NewLine into the output table
                                          %5. Remove rows till this point from the Inuput table.
                                          %6. Repeat 1-5 till input table is empty.

            if isempty(SpkrSubTab)
                break
            end
            
            CurrInd = 1; %start at the 1st voc in the table
            NewLine = SpkrSubTab(CurrInd,:); %get the current line

            if numel(SpkrSubTab.start) == 1 %check if the SpkrSubTab only has one row
                MergedTabForSpkr = [MergedTabForSpkr; NewLine]; %if yes, we have reached the end of the input table, save the last line into the output table and exit the while loop
                break
            end

            while true %infinite while loop; this one is to keep track of the current chain of vocs being merged, if applicable
                if SpkrSubTab.start(CurrInd+1)-NewLine.xEnd <= IviMergeTol %check if the Ivi for the end of the ith voc and the start of the (i+1)th voc is 0. We
                    %this value as IviMergeTol (See towards the beginning of this function)
                    CurrInd = CurrInd + 1; %if yes, update CurrInd
                    NewLine.xEnd = SpkrSubTab.xEnd(CurrInd); %and update the end time of the ith voc with the end time of the (i+1)th voc
                    TotalMergeCt = TotalMergeCt + 1; %one merge has been performed; update merge count
                    if CurrInd == numel(SpkrSubTab.start) %if the updated CurrInd = number fo rows in the table, break
                        break
                    end
                else
                    break %if there is no 0 Ivi, break
                end
            end

            MergedTabForSpkr = [MergedTabForSpkr; NewLine]; %Write NewLine to output table
            SpkrSubTab(1:CurrInd,:) = []; %remove rows till this point from input table
        end
    end
%------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
end