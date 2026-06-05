clear; clc

%%@author info, July 2022; updated Dec 2023;

%This script zscores the LENA- and human-listener labelled dataset (CHN and AN data z-scored together), and puts them back together.

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%CHANGE PATHS ACCORDINGLY
BasePath =  '~/BaseDataPath/Data/';
destinationpath_Hum = strcat(BasePath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A7_HlabelTS_Zscored/');
destinationpath_LENA = strcat(BasePath,'LENAData/A7_ZscoredTSAcousticsLENA/');

%go to folder with Joined Acoustics data, for both LENA- and Human0-listener labelled data, and get files.
LENA_TSpath = strcat(BasePath,'LENAData/A6_AcousticsTSJoinedwPauses/');  cd(LENA_TSpath); %LENA data
LENA_TSfiles = dir('*_AcousticsTSJoined.csv');
Hum_TSpath = strcat(BasePath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A6_TSwSubrecsMerged/');  cd(Hum_TSpath); %human listener-labelled data
Hum_TSfiles = dir('*_TSSubrecMerged.csv');
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------

dB_ChnAn = []; logf0_ChnAn = []; logDur_ChnAn = []; %Initialise vectors to store dB, f0, and duration values to zscore all together
C_zdB = cell(numel(LENA_TSfiles) + numel(Hum_TSfiles),1);  C_zlogf0 = cell(numel(LENA_TSfiles) + numel(Hum_TSfiles),1); %Cell arrays for z-scored values
C_zlogDur = cell(numel(LENA_TSfiles) + numel(Hum_TSfiles),1); 
LENAandHum_TScell = cell(numel(LENA_TSfiles) + numel(Hum_TSfiles),1);
NumelChnAn = [];

%To conveniently store in cell arrays, these are the variable names for the tables: 
% LENA: 'wavfile', 'speaker', 'start', 'xEnd', 'duration, 'meanf0', 'dB', 'FileNameUnMerged', 'SectionNum'
% HUM: 'wavfile', 'speaker', 'start', 'xEnd', 'duration, 'meanf0', 'dB', 'Annotation', 'FileNameUnMerged', 'SectionNum' 

%go through TSFiles, LENA and Hum-listener labelled
[LENAandHum_TScell,dB_ChnAn,logf0_ChnAn,logDur_ChnAn,NumelChnAn] = GetInputsForZscoring(LENA_TSfiles,LENAandHum_TScell,0,dB_ChnAn,logf0_ChnAn,logDur_ChnAn,NumelChnAn);
[LENAandHum_TScell,dB_ChnAn,logf0_ChnAn,logDur_ChnAn,NumelChnAn] = GetInputsForZscoring(Hum_TSfiles,LENAandHum_TScell,numel(LENA_TSfiles),dB_ChnAn,logf0_ChnAn,logDur_ChnAn,NumelChnAn);

%get z-scored values
zdB_ChnAn = (dB_ChnAn - mean(dB_ChnAn,'omitnan'))/std(dB_ChnAn,'omitnan'); 
zlogf0_ChnAn = (logf0_ChnAn - mean(logf0_ChnAn,'omitnan'))/std(logf0_ChnAn,'omitnan'); 
zlogDur = (logDur_ChnAn - mean(logDur_ChnAn,'omitnan'))/std(logDur_ChnAn,'omitnan'); 

csumNumelChnAn = [0 cumsum(NumelChnAn)]; %cumulative sum of the vector of the number of utterances in each file (obtained using numel). This will help us put back z-scored data to their 
%respective files

for i  = 1:length(csumNumelChnAn)-1 %each vector can be put back together by picking out the cumsum(i) + 1 to cumsum(i+1) elements together
   C_zdB{i} =  zdB_ChnAn(csumNumelChnAn(i)+1:csumNumelChnAn(i+1));
   C_zlogf0{i} = zlogf0_ChnAn(csumNumelChnAn(i)+1:csumNumelChnAn(i+1));
   C_zlogDur{i} = zlogDur(csumNumelChnAn(i)+1:csumNumelChnAn(i+1)); 
end

%go through data tables (saved in LENAandHum_TScell), re-constitute, and save file
SaveZscoreData(destinationpath_LENA,LENAandHum_TScell,LENA_TSfiles,0,C_zlogf0,C_zdB,C_zlogDur,'_AcousticsTSJoined.csv','_ZscoredAcousticsTS_LENA.csv'); %LENA
SaveZscoreData(destinationpath_Hum,LENAandHum_TScell,Hum_TSfiles,numel(LENA_TSfiles),C_zlogf0,C_zdB,C_zlogDur,'_TSSubrecMerged.csv','_ZscoredAcousticsTS_Hum.csv') %human listener-labelled data

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%user-defined functions to get all necessary inputs for z-scoring across lENA and human listener labelled data and to put the z-scored data back into their respective data tables, and 
% save the new tables

%-------------------------------------------------------------------------------------
%This function outputs all the necessary bits and pieces for the z-scoring. The way we do the z-scoring across the entire LENA and human-listenr labelled data is as follows:
% the entire human-listener- and lENA labelled datasets' acoustics are smushed together into one big vector. So, there is one single, huge vector for all the amplitudes smushed together,
% and similarly for logged-pitch and logged-duration. We name these vectors, respectively, dB_ChnAn, logf0_ChnAn, and logDur_ChnAn. We do this in the order of all LENA data followed 
% by the human-listener labelled data (in the order they appear in the time series directory). We also keep track of the number of utterances in each individual data file so we can
% reconstitute the z-scored data into their corresponding LENA and human-listener labelled files.

%Outputs: -LENAandHum_TScell: cell array that has all LENA and human-listener labelled data tables (after we go through LENA and hum data). We will replace the dB, meanf0, and duration
            % vectors in these tables with the z-scored ones.
         %- dB_ChnAn,logf0_ChnAn,logDur_ChnAn: output vectors that contain, respectively, the smushed together amplitude, log mean pitch, and log duration data from all LENA and hum files.
         %- NumelChnAn: the vector keeping track of the number of utterances in every data file.

%Inputs: - TSfiles: directory information from dir() on the LENA or human-listener labelled time series directories.
        %- LENAandHum_TScell: the cell array in which the deta tables (both LENA and hum) are stored.
        %- AddToIndex: the index modifier to keep track of whether we are adding LENA or human-labelled data to the vector containing all data smushed together. So, given that i is the 
            %index we are tracking as we go through the TSfiles directory, since we smush together LENA data first, the i-th file smushed into the vector for dB or logf0 or log-duration
            % (or the i-th table stored in the LENAandHumTScell array where we store all the tables we are reading in, or the i-th element in the NumelChnAn vector) will correspond 
            % to the i-th LENA file in the LENA TS directory. However, since we are adding the human-listener data AFTER the LENA data, to properly keep track of the data, if j is the
            % index we are tracking as we go through the human-listener data directory, then it will be the (numel(LENA_TSfiles) + j)-th element file that is smushed into the vector
            % that would correspond to the j-th human-listener labelled file. Thus, AddToIndex = 0 for LENA, and numel(LENA_TSfiles) for human-listsner labelled data.
        %- dB_ChnAn, logf0_ChnAn, logDur_ChnAn: vectors to smush all amplitude, log-pitch, and log-duration data into.
        %- NumelChnAn: vector to keep track of the number of utterances in each data table (also need to use AddToIndex for indexing this one).

function [LENAandHum_TScell,dB_ChnAn,logf0_ChnAn,logDur_ChnAn,NumelChnAn] = GetInputsForZscoring(TSfiles,LENAandHum_TScell,AddToIndex,dB_ChnAn,logf0_ChnAn,logDur_ChnAn,NumelChnAn)
    for i = 1:numel(TSfiles) %go through list of files
        TSTab = readtable(TSfiles(i).name,'Delimiter',','); %Read in table
        LENAandHum_TScell{AddToIndex + i,1} = TSTab; 
        
        if ~isempty(TSTab.duration(TSTab.duration <= 0)) %error checks
            error('This human-listener labelled file has 0 or negative durations')
        end

        if ~isempty(TSTab.meanf0(TSTab.meanf0 <= 0))
            error('This human-listener labelled file has 0 or negative pitch values')
        end

        if ~isempty(TSTab.dB(TSTab.dB <= 0))
            error('This human-listener labelled file has 0 or negative amplitude values')
        end
    
        dB_ChnAn = [dB_ChnAn; TSTab.dB]; logf0_ChnAn = [logf0_ChnAn; log10(TSTab.meanf0)]; logDur_ChnAn = [logDur_ChnAn; log10(TSTab.duration)]; %concatenate dB, F0, duration:
        NumelChnAn(AddToIndex + i) = numel(TSTab.dB); %get number of elements in AN + all CHN vectors
    end
end

%-------------------------------------------------------------------------------------
%This function picks out each data table from LENAandHum_TScell, removed the raw acoustics data columns, and replaces them wityh teh z-scored ones, and saves the file.

%Inputs: - destinationpath: path to the destination folder
        %- LENAandHum_TScell: the cell array in which the deta tables (both LENA and hum) are stored. (see user-defined function above for details)
        %- Dir_TSFiles: directory information from dir() on the LENA or human-listener labelled time series directories.
        %- AddToIndex: The index modifier to keep track of whether we are re-constituting LENA or human-labelled data into their own data tables 
        %- C_zlogf0,C_zdB,C_zlogDur: cell arrays with z-scored acoustics vectors
        %- StrToRemoveFromFn, StrToAddToFn: strings to remove from the file name (to get the filename root) and to add to the file name (to get the file name to save).
function [] = SaveZscoreData(destinationpath,LENAandHum_TScell,Dir_TSFiles,AddToIndex,C_zlogf0,C_zdB,C_zlogDur,StrToRemoveFromFn,StrToAddToFn)

    cd(destinationpath) %go to destination path

    for i = 1:numel(Dir_TSFiles) %go through cell array with TS files 
        New_TSTab = removevars(LENAandHum_TScell{AddToIndex + i,1},{'meanf0','dB','duration'}); %Get original data table stored in the cell array and remove raw acoustics 
    
        New_TSTab.logf0_z = C_zlogf0{AddToIndex + i}; New_TSTab.dB_z = C_zdB{AddToIndex + i}; New_TSTab.logDur_z = C_zlogDur{AddToIndex + i}; %add z scored acoustics
       
        NewFn = strcat(erase(Dir_TSFiles(i).name,StrToRemoveFromFn),StrToAddToFn); %get the new file name
        writetable(New_TSTab,NewFn) %write table to destination
    end
end
