clear; clc

%%@author info
%Dec 2021
%Code to %-run getIndividualAudioSegments.m on each .wav file in the LENAExports folder's subfolders; 
         %-to run getAcousticsTS for human labelled data
         %-to delete all the small wave files from getIndividualAudioSegmentsHUMlabel.m after each iteration so memory isn't cluttered

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------         
%get .wav files to process acoustics for the annotated vocs' CHANGE PATHS AS NECESSARY
WAVfolderpath = '~/BaseCloudPath/LENAExports_Renamed/';%path for folders with .wav files
cd(WAVfolderpath)
WAVdir = dir('*'); %get all files and folders
N = setdiff({WAVdir([WAVdir.isdir]).name},{'.','..'}); %get all folders ONLY except the . and .. folders

BasePath = '~/BaseDataPath/Data/HUMLabelData/A2_HUMLabelData_PostCleanUp/'; %set base path
AnnotFilepath = strcat(BasePath,'A3_HlabelsOlpProcessed/'); %specifuy paths for csv files with annotation info
cd(AnnotFilepath)
S = dir('*_OlpProc.csv'); %get all relevant files

wavFileDir = '~/Downloads/TempWavFiles/'; %directory to store temp wav files
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------

%Now, we go through the annotated eaf files one by one, match to corresponding wav files, and get acoustics. 
for i = 1:numel(S) 
    
    i
    
    %----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    fileroot = regexprep(S(i).name,'_OlpProc.*.csv',''); %get fileroot by replacing '_OlpProc.csv'; CHANGE STRINGS INSIDE FUNCTION CALL AS NECESSARY.
    %----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    InfantID = fileroot(1:4); %get infant ID
    
    for j = 1:numel(N) %go through the .wav file folders to see which infant ID matches
        FolderNameRoot = N{j};
        if contains(FolderNameRoot,InfantID) == 1
            WAVfilepath = strcat(WAVfolderpath,N{j}); %get the path to the wav files
        end
    end
    
    %Once folder is identified, check if corresponding .wav file exists in the folder
    cd(WAVfilepath)
    WAVfilename = strcat(fileroot,'.wav');

%     %------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%     %A note: A few files that are parts of day long recordings (with the suffix a, b, etc) don't find a wave file match, because the wave files aren't necessarily split up 
%     % into a, b, etc. Make sure to check for this and do those manually if necessary
%     if ~isfile(WAVfilename) %DEBUGGING bit to find wav files that aren't fully properly named and hence, don't get matched to a csv file
%        WAVfilename
%     end
%     %------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    %----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    TSfile = strcat(BasePath,'A4_HlabelTS_OlpProcessed/',fileroot,'_TSOlpProc.csv'); %get TS file name; CHANGE PATHS AND STRINGS INSIDE FUNCTION CALL AS NECESSARY.
    %----------------------------------------------------------------------------------------------------------------------------------------------------------------------

    if strcmp(WAVfilename,'0056_000305b.wav') %this is to account for these two .wav filenames that don't quite match
        WAVfilename = '0056_000305.wav';
    elseif strcmp(WAVfilename,'0441_000312b.wav')
        WAVfilename = '0441_000312.wav';
    end

    if (isfile(WAVfilename) == 1) && (isfile(TSfile) == 0) %if wave file exists and if TSfile does not exist in final folder, continue

        bigWavFile = strcat(WAVfilepath,'/',WAVfilename); %get wave file name with path
        OutFileBase = strcat(wavFileDir,fileroot);
        buffer = 0; %0 is the buffer value we want
        speakers = {'CHN','AN','OLP'}; %These are the speaker types we want; the OLP is just so that the vocs or subvocs tagged as OLP won't be thrown out in the TS file, 
        % so we can reconstitute the non-chopped up vocs without issue
        %----------------------------------------------------------------------------------------------------------------------------------------------------------------------
        AnnotFile = strcat(AnnotFilepath,fileroot,'_OlpProc.csv'); %get relevant annotation csv file; CHANGE STRINGS INSIDE FUNCTION CALL AS NECESSARY.
        %----------------------------------------------------------------------------------------------------------------------------------------------------------------------
        getIndividualAudioSegmentsHUMlabel(AnnotFile,bigWavFile,OutFileBase,buffer,speakers) %get individual audio segments based on onset and offset time from AnnotFile
        %These segments will then be used to compute acoustics. See relevnt user-defined function for details

        %define function inputs for getacousticsTS_HUMlabel
        wavfilebase = fileroot;
        %----------------------------------------------------------------------------------------------------------------------------------------------------------------------
        outFile = strcat(BasePath,'TempTS/',fileroot,'_TSOlpProc.csv'); %Note that TempTS is a temporaru directory I have created so there is a place to put the TS files
        %before moving them to the final destination. This is so that we can check and make sure that everything is working as intended before moving to the final destination
        %CHANGE PATHS AND STRINGS INSIDE FUNCTION CALL AS NECESSARY.
        %----------------------------------------------------------------------------------------------------------------------------------------------------------------------
        getacousticsTS_HUMlabel(AnnotFile,wavFileDir,wavfilebase,outFile,speakers)

        %----------------------------------------------------------------------------------------------------------------------------------------------------------------------
        %once complete, move file to TimeSeries folder (final destination); CHANGE PATHS AND STRINGS INSIDE FUNCTION CALL AS NECESSARY.
        movefile(outFile,strcat(BasePath,'A4_HlabelTS_OlpProcessed/'));

        %delete all the small wavefiles created
        which_dir = '~/Downloads/TempWavFiles/';
        filestr = strcat(which_dir,fileroot,'*.wav');
        %----------------------------------------------------------------------------------------------------------------------------------------------------------------------
        dinfo = dir(filestr); %get all contents for the specific file name root
        dinfo([dinfo.isdir]) = [];   %skip directories
        filenames = fullfile(which_dir, {dinfo.name}); %get filenames
        delete(filenames{:}) %delete all
    end     
end

clear all; %just so everything is cleared