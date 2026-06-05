clear; clc

%%@author info, March 2022

%This script stitches together TS + pauses from the same recording day. This is because we have recordings that are named: <File name root>_Section1, <File name root>_Section2, where 
% these are both from the same infant on the same day.
%In addition, the name of the orginal audi files (which contain potentially identifying info) have been removed from the wavfile column in the output files
% from this script!.

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%CHANGE PATHS AND STRINGS ACCORDINGLY
BasePath = '~/BaseDataPath/';
destinationpath = strcat(BasePath,'Data/LENAData/A6_AcousticsTSJoinedwPauses/'); %Set destination path where tables will be written

cd(strcat(BasePath,'Data/MetadataFiles')); %cd to path with metadata files
opts = detectImportOptions('MetadataInfAgeAndID.csv'); %Read in table with .its file details; make sure to read in infant code as string
opts = setvartype(opts, 'InfantID', 'string');
FnAgeInfantIdDetails = readtable('MetadataInfAgeAndID.csv',opts);

cd(strcat(BasePath,'Data/LENAData/A5_TimeSeriesWPauses/')); %cd into folder with TS files and get all files
TSFiles = dir('*_TSwPauses.csv');
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------

%Go through all files and get file roots (without section numbers, a, b, etc.)
for i = 1:numel(TSFiles)
    NewName = strrep(TSFiles(i).name,'_TSwPauses.csv','');
    FileNameRoot_Temp{i,1} = NewName(1:11); %Get first 11 characters, because thsi is <4 character infant id>_<Age in YYMMDD>
end

%Now we pick out all the files with the same file root (a, b, etc, provide subrec info, so we will merge these)
U_FileNameRoot = unique(FileNameRoot_Temp);  %Get unique file name roots

%Get propertynames of one of the TSfiles tables to make an empty table so as to vertically concatenate tables with the same file name root 
TabToReadVarNames = readtable(TSFiles(1).name,'Delimiter',',');
VarNamesForEmptyTab = TabToReadVarNames.Properties.VariableNames;

%Go through unique filename roots and match root name to full file names
for i = 1:numel(U_FileNameRoot)

    %Initialise empty table with same coilumn names to concatenate tables for the recordings from sdame infant on the same day
    T_new = array2table(zeros(0,numel(VarNamesForEmptyTab)),'VariableNames',VarNamesForEmptyTab);
    
    NewTableName = strcat(destinationpath,U_FileNameRoot{i},'_AcousticsTSJoined.csv');
    u_TabFn = unique(FnAgeInfantIdDetails.FNRoot(contains(FnAgeInfantIdDetails.FNRoot,U_FileNameRoot(i)))); %Table containing filenames corresponding to
    %each unique, cleaned up file name root
    u_TabInfantId = unique(FnAgeInfantIdDetails.InfantID(contains(FnAgeInfantIdDetails.FNRoot,U_FileNameRoot(i)))); %Get corresponding infant ID and age
    u_TabAge = unique(FnAgeInfantIdDetails.InfantAge(contains(FnAgeInfantIdDetails.FNRoot,U_FileNameRoot(i))));

    AgeDiff = u_TabAge - u_TabAge'; %Get difference of ages between all elements
    AgeDiff = AgeDiff(AgeDiff > 5); %Only keep age differences greater than 5 days. This is to account for subrecordings that has +/1 age diff due to
    %reading in DOBs or recording dates without correcting for local timezone vs. Greenwich

    InfantID{i,1} = unique(u_TabInfantId); InfantAgeDays(i,1) = min(u_TabAge);

    %Counter variable to get name of files before stitching subrecs together + get number of entries in those tables. We will use this to add a file name (before stitching subrecs together) 
    % column to the final table
    PreSticthFnCtr = 0; 
    PreStitchFn = {}; PreStitchFileNumCols = []; %initialise

    if (numel(unique(u_TabInfantId)) == 1) && (numel(AgeDiff) == 0)%If this corresponds to a single age and id 
        %Go through matching file names and stitch together
        for j = 1:numel(u_TabFn) %Match these to files names of TS files
            for k = 1:numel(TSFiles)
                if contains(TSFiles(k).name,u_TabFn(j))
                    T_temp = readtable(TSFiles(k).name,'Delimiter',',');

                    %Set the last entry in SubrecEnd variable to 1, indicating this is the end of a recording (or subrecording), so in case this gets stitched to another subrec, we know this 
                    % is the end point and account for that in step sizes
                    T_temp.SubrecEnd(end) = 1;
                    T_new = [T_new; T_temp]; %Stitch together

                    PreSticthFnCtr = PreSticthFnCtr + 1; %Increment counter
                    PreStitchFn{PreSticthFnCtr} = erase(TSFiles(k).name,'_TSwPauses.csv'); %Get file name
                    PreStitchFileNumCols(PreSticthFnCtr) = size(readtable(TSFiles(k).name,'Delimiter',','),1); %Get number of entries for the file
                end
            end
        end
    else %File names and infant codes of rogue files, test to see everything is working
        u_TabInfantId
        u_TabAge
    end

    %Get vector to store file name info for all subrecs stitched into one file. Adding this will be useful when we get matching sections from LENA data for human labelled data so that we 
    %don't match sections between different subrecs of the same daylong recording
    FnamePreSticthVec = cell(sum(PreStitchFileNumCols),1); %Create cell array to store file names corresponding to each file stitched
    PreStitchFileNumelCumsum = [0 cumsum(PreStitchFileNumCols)]; %Get vector with info about how many repeats of a file name should be there
    for j = 1:numel(PreStitchFileNumelCumsum)-1
        [FnamePreSticthVec{PreStitchFileNumelCumsum(j)+1:PreStitchFileNumelCumsum(j+1)}] = deal(PreStitchFn{j});
    end
    T_new.FileNameUnMerged = FnamePreSticthVec; %Add column

    SectionNumVec = GetSectionNumVec(T_new); %get section number info from subrecend colum
    T_new.SectionNum = SectionNumVec; %add section number column to table
    T_new = removevars(T_new,{'SubrecEnd'}); %remove the subrecend column

    %re-compute duration as the difference between end and start of a voc (some durations from the acoustics TS code have NaN values because the 
    % corresponding pitch and/or amplitude could not be calculated)
    Duration = T_new.xEnd - T_new.start;
    if ~isempty(Duration(Duration <= 0)) %check that there are no negative or 0 durations
        error('Zero or negative durations present')
    end
    T_new.duration = Duration; 

    %Edit wavfile column from table: this column has original file name (and hence, potential id info). This way, only the segment number and speaker ID (chnsp, chnnsp, etc) remains
    T_new.wavfile = regexprep(T_new.wavfile,'.*_Segment','Segment');
    writetable(T_new,NewTableName) %Write table to file
end

%Get age in months: separate into 3,6,9 and 18, and others
for i = 1:numel(InfantAgeDays)
    if (InfantAgeDays(i)/30 > 2.5) && (InfantAgeDays(i)/30 < 4)
        InfantAgeMonth(i,1) = 3;
    elseif (InfantAgeDays(i)/30 > 5.5) && (InfantAgeDays(i)/30 < 7)
        InfantAgeMonth(i,1) = 6;
    elseif (InfantAgeDays(i)/30 > 8.5) && (InfantAgeDays(i)/30 < 10)
        InfantAgeMonth(i,1) = 9;
    elseif (InfantAgeDays(i)/30 > 17.5) && (InfantAgeDays(i)/30 < 19)
        InfantAgeMonth(i,1) = 18;
    else
        InfantAgeMonth(i,1) = round(InfantAgeDays(i)/30); 
    end
end

FileNameRoot = U_FileNameRoot; %Get the vector of unqiue file roots AFTER stitching sub-recordings from the same infant at the same age together

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
cd(strcat(BasePath,'Data/MetadataFiles/')); %Go to metadata folder; CHANGE PATH ACCORDINGLY
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
T_Metadata = table(FileNameRoot,InfantAgeDays,InfantAgeMonth,InfantID);
writetable(T_Metadata,'MergedTSAcousticsMetadata.csv')