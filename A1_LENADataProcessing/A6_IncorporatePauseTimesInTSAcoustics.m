clear; clc

%@author info; Feb 2022

%Code to account for recorder pause times in acoustics time series (LENA data)

%-------------------------------------------------------------------------------------------------------------------------------------------------------
%get relevant paths; PLEASE CHANGE ACCORDINGLY; below, path for acoustics time series and pause times
TSpath = '~/BaseDataPath/Data/LENAData/A4_TimeSeries';
PausePath = '~/BaseDataPath/Data/LENAData/A3_PauseTimes';
%get destination path
destinationpath = '~/BaseDataPath/Data/LENAData/A5_TimeSeriesWPauses/';
%-------------------------------------------------------------------------------------------------------------------------------------------------------

%Go to time series folder and dir; and same for pause times folder
cd(TSpath); TSdir = dir('*TS.csv');
cd(PausePath); Pausedir = dir('*PauseTimes.txt');

%The idea is to label the last adult/infant event in a subrecording with a
%1, and all other events with 0. So, thsi would look something like this:
% AN  - start time - end time - ----- lastevent = 0
% CHN - start time - end time - ----- lastevent = 0
% CHN  - start time - end time - ----- lastevent = 0
% CHN - start time - end time - ----- lastevent = 0
% AN  - start time - end time - ----- lastevent = 1
% CHN - start time - end time - ----- lastevent = 0
%Then, if the ith event is indexed with 1 for lastevent, the step (i+1)-i won't be counted

for i = 1:numel(TSdir) %Go throigh TS files, read each and read in corresponding pause times file
    
    TStab = readtable(TSdir(i).name,'Delimiter',','); %Read TS file; delimiter here ensures that all files are read in correctly
    TSfileroot = strrep(TSdir(i).name,'_TS.csv',''); %Get file root
    SubrecEnd = zeros(size(TStab.xEnd)); %Initialise vector of zeros to store end of subrecording index
    FoundMatch = 0; %Flag to see if there is a missing pausetimes variable
    NewFileName = strcat(destinationpath,TSfileroot,'_TSwPauses.csv'); %Get the file name for the output file

    if isfile(NewFileName) == 0 %Proceed only if file doesnt already exist
        for j = 1:numel(Pausedir) %Find matching pause times file and read
            if strcmp(TSfileroot,strrep(Pausedir(j).name,'_PauseTimes.txt','')) == 1
                
                FoundMatch = FoundMatch + 1; %Update the flag variable
                Pausetab = readtable(Pausedir(j).name);
    
                %Procedd only if there ARE pauses: note that readtable only reads as not-empty if there is more than one row in the pause time info. If there is only one row, 
                %that means there were no pauses, so this is perfectly fine
                if isempty(Pausetab) == 0
                    i
                    TerminateInd = zeros(size(Pausetab.Var2)); %Initialise vector to store indices for last end times in subrec
        
                    %Index the last end time in each subrecording with 1, for the SubrecEnd variable and append it to the TS table
                    for k = 1:numel(Pausetab.Var1)
                        EndIndex = 1:numel(TStab.xEnd); %Temporary vector with indices for End times
                        TempEnd = EndIndex(TStab.xEnd <= Pausetab.Var2(k)); %Pick out all end times less than or equal to each pause time; 
                        %Var2 is the one storing the end time of each subrec
                        if isempty(TempEnd) == 0 %If there ARE end time indices before pause
                            TerminateInd(k) = TempEnd(end); %Get index of the last entry in this subset
                        end
                    end
        
                    TerminateInd = TerminateInd(TerminateInd ~= 0); %Remove zeros from terminateind
                    SubrecEnd(TerminateInd) = 1; %If an end time is the last in a subrecording, index it with one
                end
            end
        end
    
        TStab.SubrecEnd = SubrecEnd; %Append vector to TStab
        
        %Warnings
        if FoundMatch == 0
            fprintf('This TS file does not have a matching Pause Times file %s',TSfileroot)
        elseif FoundMatch > 1
            fprintf('This TS file has multiple matching Pause times files %s',TSfileroot)
        end
    
        writetable(TStab,NewFileName)   %Write TS with pause info to file 
    end
end





