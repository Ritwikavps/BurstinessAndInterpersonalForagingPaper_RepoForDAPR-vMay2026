function [] = getIndividualAudioSegmentsHUMlabel(AnnotFile,bigWavFile,OutFileBase,buffer,speakers)

% Originally written by:%@author info (@author email)
% Adapted by %@author info, Dec 2021, to use in the extraction of acoustics for 5 minute human labelled data segments, based on the nature of the
% input files with CHN, AN, and OLP start and end times and human labels that we have

% We already have the start and end times and human label (infant voc type or adult utterance direction, as applicable, as well as OLP labels, after processing 
% overlaps) for the 5 min human labelled segements. We will store these start and end times as StartEndTimes{2} and {3}. And have a cell array of size 
% numel(StartEndTimes{2})-by-1  with'CHN', 'AN', or 'OLP' repeated as applicable as StartEndTimes{1}. 
%
% Instructions:
% 1.) If you wish, create a new a folder to hod the small wav files (this program will produce a lot of them)
% 2.) In the command window, type: getIndividualAudioSegments(AnnotFile,bigWavFile,OutFileBase,buffer,speaker) where:
%     AnnotFile = The name of the Ahumen liostener labels .csv files
%         e.g., '~/Participants/WW05/e20131210_144819_009143_Humlabels.csv'
%     bigWavFile = The full .wav file of the recording
%         e.g., '~/Participants/WW05/e20131210_144819_009143.wav'
%     OutFileBase = Where audio segments will be written + the beginning part of each segment filename
%         e.g., '~/Participants/WW05/Segments/e20131210_144819_009143' 
%     buffer = Should be in seconds and will add some time to the beginning and ending of each audio segment before extracting it 
%         e.g., '0' or '.3'
%     speakers = An array holding the speaker types whose segments you would like to output. 
%     getIndividualAudioSegmentsHUMlabel('~/Participants/WW05/e20131210_144819_009143_HumLabels.csv',...
%               '~/Participants/WW05/e20131210_144819_009143.wav',...
%               '~/Participants/WW05/Segments/e20131210_144819_009143','0',{'CHN','AN'});
% 3.) Press Return to run the program

%play the individual speaker segments:
AnnotTable = readtable(AnnotFile,'Delimiter',','); %read adult file
StartTime = AnnotTable.StartTimeVal; %get start time 
EndTime = AnnotTable.EndTimeVal; %get end time

%create vector of labels: CHN for Chidl, AN for adult, OLP for OLP
for i = 1:numel(StartTime)
    if strcmpi(AnnotTable.Annotation{i},'OLP')
        Labels{i,1} = 'OLP';
    elseif (contains(AnnotTable.TierTypeVec{i},'Infant Voc Type','IgnoreCase',true)) && (strcmpi(AnnotTable.Annotation{i},'OLP') ~= 1)
        Labels{i,1} = 'CHN';
    elseif (contains(AnnotTable.TierTypeVec{i},'Adult Utterance','IgnoreCase',true)) && (strcmpi(AnnotTable.Annotation{i},'OLP') ~= 1)
        Labels{i,1} = 'AN';
    end
end

StartTime = StartTime/1000; %put the start and end times as well as all labels together; Dividing start and end times by 1000 to correct units
EndTime = EndTime/1000;

%Recast starttime, endtime, and labels into StartEndTimes cell array
StartEndTimes{2} = StartTime; StartEndTimes{3} = EndTime; StartEndTimes{1} = Labels;

fs = 16000;

for segment = 1:size(StartEndTimes{1,1},1)
    speaker = StartEndTimes{1,1}(segment);
    if sum(strcmp(speaker,speakers)>0)
        %hacky way to make sure that the range in audioread has start < end
        %proceed only if this satisfied
        if max(round((StartEndTimes{1,2}(segment)-buffer)*fs),1) < round((StartEndTimes{1,3}(segment)+buffer)*fs)
            smallWav = audioread(bigWavFile,[max(round((StartEndTimes{1,2}(segment)-buffer)*fs),1),round((StartEndTimes{1,3}(segment)+buffer)*fs)]);
            audiowrite([OutFileBase,'_Segment_',num2str(segment),'_',char(StartEndTimes{1,1}(segment)),'.wav'],smallWav,fs);
        end
    end
end