clear; clc

%%@author info
%April 2021
%Code to 
    %-run getIndividualAudioSegments.m on each .wav file in the LENAExports folder's subfolders; 
    %-to run getAcousticsTS for all speakers, CHNSP only, and adult only for the speciifc dataset (and store them in a TS folder)
    %-to delete all the small wave files from getIndividualAudioSegments.m after each iteration so memory isn't cluttered        

%--------------------------------------------------------------------------------------------------------------------------------------------------------
%CHANGE PATH ACCORDINGLY
cd ~/BaseCloudPath/LENAExports_Renamed/ %Path to .wav files
BasePath = '~/BaseDataPath/'; %Basepath to the project
%--------------------------------------------------------------------------------------------------------------------------------------------------------

S = dir('*'); %Get all files and folders
N = setdiff({S([S.isdir]).name},{'.','..'}); %Get all folders ONLY except the . and .. folders

parfor i = 1:numel(N) %Go through each subfolder; parallelising for faster processing
    %--------------------------------------------------------------------------------------------------------------------------------------------------------
    %CHANGE PATH ACCORDINGLY
    desiredpath = strcat('~/BaseCloudPath/LENAExports_Renamed/',N{i}); %Path to each infant's folder
    %--------------------------------------------------------------------------------------------------------------------------------------------------------
    cd(desiredpath) 
    newdir = dir('*.wav'); %Get all .wav files in the directory
    
    for j = 1:numel(newdir) %Go through each wavefile
        
        %Get the root of the filename - this is the bit that all associated files will have in common
        NameRoot = strrep(newdir(j).name,'.wav','');  %Replace .wav with '' so we can find same root file
        
        %Inputs for this:
            %SegmentsFile: the name of the segments csv file corresponding
                %to the wave file (with path)
            %bigWavFile: the wave files in the newdir structure: eg: e20170321_104125_010587.wav
            %OutFileBase: Where audio segments will be written + the beginning part of each segment filename
            %Buffer: Should be in seconds and will add some time to the beginning and ending of each audio segment before extracting it e.g., 0 or .3
            %speakers: An array holding the speaker types whose segments you would like to output. E.g. {'CHNSP','FAN','MAN'} for child speech-related, female adult, and male adult, "near" (loud) segments only. 
     
        %-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        %CHNAGE PATH TO SAVE ACCORDINGLY
        SegmentsFile = strcat(BasePath,'Data/LENAData/A2_Segments/',NameRoot,'_Segments.csv'); %To use in downstream function
        TSfile = strcat(BasePath,'Data/LENAData/A4_TimeSeries/',NameRoot,'_TS.csv'); %To check if TS file exists
        %-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        if (isfile(SegmentsFile) == 1) && (isfile(TSfile) == 0)%Continue ONLY if the corresponding segments file exists AND if the TSfile does not exist (to avoid repeating computations)
           
            [i j] 

            bigWavFile = strcat(desiredpath,'/',newdir(j).name);
            %--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            %CHANGE PATH ACCORDINGLY;
            %Note that this is a directory I explicitly created to dyump the temp files into, so you'll have to do something similar
            OutFileBase = strcat('~/Downloads/TempWavFiles/',NameRoot); 
            %--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            buffer = 0; %0 is the buffer value we want
            speakers = {'CHNSP','CHNNSP','FAN','MAN'}; %These are the speaker types we want
            getIndividualAudioSegments(SegmentsFile,bigWavFile,OutFileBase,buffer,speakers);

            %Get acoustics and timeseries for adult and CHNSP
            %Inputs:
                %SegmentsFile = The name of the Segments .csv file; same as above
                %wavFileDir: The directory where the small audio segments live
                %wavfilebase: The name base for the .wav file segments
                %outFile: The path and name of the output file where you want the time series to be written
            wavfilebase = NameRoot;
            %-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            %CHANGE PATHS ACCODINGLY
            wavFileDir = '~/Downloads/TempWavFiles/';
            outFile = strcat(BasePath,'Data/LENAData/TempTS/',NameRoot,'_TS.csv'); 
            %Note that TempTS is a directory I created to temporarily store the time series file before moving to the final time series folder
            %-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            speakers = {'CHNSP','CHNNSP','FAN','MAN'};
            getAcousticsTS(SegmentsFile,wavFileDir,wavfilebase,outFile,speakers);

            %-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            %CHANGE PATH ACCORDINGLY
            movefile(outFile,strcat(BasePath,'Data/LENAData/A4_TimeSeries'));
            which_dir = '~/Downloads/TempWavFiles'; %delete all the small wavefiles created; 
            %-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            filestr = strcat(which_dir,'/',NameRoot,'*.wav');
            dinfo = dir(filestr); %Get all contents for the specific file name root
            dinfo([dinfo.isdir]) = [];   %Skip directories
            filenames = fullfile(which_dir, {dinfo.name}); %Get filenames
            delete( filenames{:} ) %Delete all
        end 
    end 
end

clear all %just so EVERYTHING is cleared