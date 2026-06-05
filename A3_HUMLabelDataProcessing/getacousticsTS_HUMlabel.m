function getacousticsTS_HUMlabel(AnnotFile,wavFileDir,wavfilebase,outFile,speakers)

%original author:%@author info
%adapted by: %@author info, Dec 2021

% Before running this program, run the "getIndividualAudioSegmentsHUMLabel.m" program. This program will run on the audio segments you created with that program.
%
% Instructions:
% 1.) Be sure you have downloaded the "getPraatAcoustics.m" script, as this
% script calls upon it.
% 2.) In the command window, type: getAcousticsTS(AnnotFile,wavFileDir,wavfilebase,outFile,speakers) where:
%       AnnotFile = The name of the human listener annotation .csv files
%         e.g., '~/Participants/WW05/e20131210_144819_009143_HumLabels.csv'
%       wavFileDir = The directory where the audio segments live
%         e.g., '~/Participants/WW05/TempSmallWavFiles/'
%       wavfilebase = The name base for the .wav file segments
%         e.g., 'e20131210_144819_009143' 
%       outFile = The path and name of the output file where you want the time series to be written
%       speakers = A list of the speakers to include in the time series
%           (note that this function is written to only admit CHN and AN as
%           speakers
%     For example: getIndividualAudioSegmentsHUMlabel('~/Participants/WW05/e20131210_144819_009143_HumLabels.csv',...
%               '~/Participants/WW05/TempSmallWavFiles/',...
%               'e20131210_144819_009143',...
%               '~/Participants/WW05/e20131210_144819_009143_AcousticsTS.txt',...
%               {'CHN','AN'});
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

StartTime = StartTime/1000; %put the start and end times as well as all labels together; Dividing by 1000 to correct units
EndTime = EndTime/1000;

%Recast starttime, endtime, and labels into StartEndTimes cell array
StartEndTimes{2} = StartTime; StartEndTimes{3} = EndTime; StartEndTimes{1} = Labels;

if exist(outFile)==2
	delete(outFile);
end

outfid = fopen(outFile,'a');
fprintf(outfid,'wavfile,speaker,start,end,duration,meanf0,dB\n');

for n = 1:size(StartEndTimes{1,1},1)
	speaker = StartEndTimes{1,1}{n};
	if sum(strcmp(speaker,speakers)>0)
	    wavFileName = [wavFileDir,wavfilebase,'_Segment_',num2str(n),'_',speaker,'.wav'];
	    wavFileNoExt = [wavfilebase,'_Segment_',num2str(n),'_',speaker];
		wavFileNoPath = [wavfilebase,'_Segment_',num2str(n),'_',speaker,'.wav'];
		duration = NaN;
		meanf0 = NaN;
		dB = NaN;
        [duration,meanf0,dB] = getPraatAcoustics(wavFileDir,wavFileNoExt);
		if ~isnan(meanf0)
			fprintf(outfid,'%s\n',strcat(wavFileNoPath,',',StartEndTimes{1,1}{n},',',num2str(StartEndTimes{1,2}(n)),',',num2str(StartEndTimes{1,3}(n)),',',num2str(duration),',',num2str(meanf0),',',num2str(dB)));
		else
			fprintf(outfid,'%s\n',strcat(wavFileNoPath,',',StartEndTimes{1,1}{n},',',num2str(StartEndTimes{1,2}(n)),',',num2str(StartEndTimes{1,3}(n)),',','NA',',','undefined',',','NA'));
		end
	end
end

fclose(outfid);
