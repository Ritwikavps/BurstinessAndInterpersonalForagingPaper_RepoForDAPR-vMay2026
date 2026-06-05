clear; clc

%%@author info
%April 2022; updated Dec 2023

%This script picks out corresponding 5 minute sections from LENA data for annotated 5 minute sections per the coding spreadsheet. 
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%CHANGE PATHS ACCORDINGLY
BasePath = '~/BaseDataPath/Data/';
destinationpath = strcat(BasePath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A8_MatchedLENAZscoreSections/'); %path to save files
LENA_ZscoredTSPath = strcat(BasePath,'LENAData/A7_ZscoredTSAcousticsLENA/'); %path to LENA tables
Hum_ZscoredTSPath = strcat(BasePath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A7_HlabelTS_Zscored/'); %path to human listener labelled 

CodingSpreadsheet = readtable(strcat(BasePath,'HUMLabelData/A1_HUMLabelData_CleanupPipeline/SummaryCsvAndTxtFiles/FNSTETSimplified.csv')); %read in coding spreadsheet
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------

cd(Hum_ZscoredTSPath); HumFiles = dir('*_ZscoredAcousticsTS_Hum.csv'); %read in human listener labelled tables (to see which sections have been annotated and to match start and end times)                                   
cd(LENA_ZscoredTSPath) %go to LENA path

for i = 1:numel(HumFiles) %go through list of human listener labelled files
    Htab = readtable(HumFiles(i).name,'Delimiter',','); %read in human-listener labelled table

    % Get the first end time and the last start time in each 5 minute section. This way, we can check these times against the section start and end times per the coding spreadsheet.
    % The rationale is that no annotated section should have annoated utterances that are fully outside of the start and end time bounds set by the coding spreadsheet. That is, the first
    % annotated utterance *should* end (at least) at or after the start time per the coding spreadsheet, and the last annotated utterance *should* start (at least) at or after the end
    % time per the coding spreadsheet.
    U_SectionNum = unique(Htab.SectionNum); %get unique section numbers
    H_FirstEndTime = []; H_LastStartTime = []; %initialise vectors to store the first end time and the last start time
    for j = 1:numel(U_SectionNum) %go through unique section numbers
        H_SubTab = Htab(Htab.SectionNum == U_SectionNum(j),:); %subset for section number
        H_FirstEndTime(j,1) = min(H_SubTab.xEnd); H_LastStartTime(j,1) = max(H_SubTab.start); %pick out the first end time and last start time  
    end

    H_FnRoot = erase(HumFiles(i).name,'_ZscoredAcousticsTS_Hum.csv'); %get the file name root
    CodingSubTab = CodingSpreadsheet(contains(CodingSpreadsheet.FileName,H_FnRoot),:); %get subset of coding spreadsheet that corresponds to the human-labelled file.

    IsSectionAnnotated = zeros(size(CodingSubTab.StartTimeSS)); %initialise vector to flag whether the section has been annotated or not
    CorrespHumSecNum = []; %This is to store the human-listener labelled section number in  the order that it corresponds to the 5 min sections as ordered in the coding spreadhseet
    % so the LENA-labelled 5 min sections can be assigned the same section number as the corresponding human-labelled 5 min section. 
    for j = 1:numel(H_FirstEndTime) %flag sections that HAVe been annotated
        for k = 1:numel(CodingSubTab.StartTimeSS)
            if (H_FirstEndTime(j) >= CodingSubTab.StartTimeSS(k)-1) && (H_LastStartTime(j) <= CodingSubTab.EndTimeSS(k)+1) %this is a 1 second buffer to the section start and end time per
                %the coding spreadsheet to account for the fact that we have thrown out overlaps. Essentially, by choppinhg up vocs into non-overlapping sub-vocs, sometimes, we retain a sub-voc that
                % is fully out side the start or end time per the coding spreadsheet, but this amounts to less than 10 vocs total across the validation dataset, and the 1 second buffer is enough to let 
                % these vocs to not trigger a flag.
                IsSectionAnnotated(k) = 1;
                CorrespHumSecNum(k) = U_SectionNum(j);
            end
        end
    end

    LENA_tab = readtable(strcat(LENA_ZscoredTSPath,H_FnRoot,'_ZscoredAcousticsTS_LENA.csv'),'Delimiter',  ',');%read in corresponding LENA data table
    MatchedLENATab = array2table(zeros(0,size(LENA_tab,2))); %initialise table to store correponsing table of matched LENA 5 minute sections, all stitched together
    MatchedLENATab.Properties.VariableNames = LENA_tab.Properties.VariableNames;
    SectionNumVec = []; %initialise vector to store the section number
    for j = 1:numel(IsSectionAnnotated) %go through the flag vector that keeps track of whether a section was annotated
        if IsSectionAnnotated(j) == 1
            LENA_SubTabByFname = LENA_tab(contains(LENA_tab.FileNameUnMerged,CodingSubTab.FileName{j}),:); %get the correct subrec file name
            LENA_SubTab = LENA_SubTabByFname((LENA_SubTabByFname.xEnd >= CodingSubTab.StartTimeSS(j) & LENA_SubTabByFname.start <= CodingSubTab.EndTimeSS(j)),:); %pick out all utterances within the coding spreadsheet
            %bounds for the specific section
            MatchedLENATab = [MatchedLENATab; LENA_SubTab]; %add to table

            SectionNumVec = [SectionNumVec; CorrespHumSecNum(j)*ones(size(LENA_SubTab.start))]; %add relevant section number to the section number vector
        end
    end

    %error check to make sure that files with unannotated sections are files that have already been flagged in FilesWithUnannotatedSections.csv. The displayed outputs from this check
    % can be verified against the list of files with unannotated sections saved as a .csv file (FilesWithUnannotatedSections.csv).
    if sum(IsSectionAnnotated) < numel(IsSectionAnnotated)
        fprintf('File %s has %i unannotated sections wrt the coding spreadsheet \n',H_FnRoot,abs(sum(IsSectionAnnotated) - numel(IsSectionAnnotated)))
    end

    MatchedLENATab.SectionNum = SectionNumVec; %Recast the section number column to the table

    NewFnToSave = strcat(destinationpath,H_FnRoot,'_MatchedLENA_ZscoreTS.csv');  
    writetable(MatchedLENATab,NewFnToSave); %   save new file
end