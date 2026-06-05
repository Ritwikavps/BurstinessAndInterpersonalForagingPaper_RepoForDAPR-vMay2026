clear; clc

%@author info; This script outputs total duration of files (day-long or validation) and the total proprtion of time occupied by target segments (CHNSP, CHNNSP, AN), all in hours 
% (and in percent of total for target segments

cd('~/BaseDataPath/Data/ResultsTabs/DataDescriptionSummaries')

%load structures and assign names, as well as read in relevant tables
load('LdaySegsDurStruct_No0IviMerged.mat'); %LENA day-long data
LdayStruct = DurStruct; 
LdayTab = readtable('LdaySegmentLevelDurationSummaryStats_No0IviMerge.csv');
load('L5minSegsDurStruct_0IviMerged_ChnAdOnly.mat'); %Validation data
L5minStruct = DurStruct; 
load('H5min-AllAdSegsDurStruct_0IviMerged_ChnAdOnly.mat');
H5minStruct = DurStruct; 
load('H5min-TAdSegsDurStruct_0IviMerged_ChnAdOnly.mat');
H5min_TAdStruct = DurStruct;

%checks to make sure that validation data only has data from required ages.
ReqAgeMos = [3 6 9 18];
if ~isequal(unique([L5minStruct.InfAgeMos]),ReqAgeMos)
    error('Lena 5 min data has data from ages other than 3, 6, 9, and 18 mos')
end

if ~isequal(unique([H5minStruct.InfAgeMos]),ReqAgeMos)
    error('Human listener labelled 5 min data has data from ages other than 3, 6, 9, and 18 mos')
end

%checks to make sure that teh list of segment labels in validation data summary structures is as expected
if ~isequal(L5minStruct(1).SegsList,H5minStruct(1).SegsList) 
    error('List of segment labels in H5 and L5 structures are not the same')
end

KeySegs = {'CHNSP','CHNNSP','AN'}; %list of key segemnts
if ~isequal(L5minStruct(1).SegsList,KeySegs') 
    error('List of segment labels in H5 and L5 is not in the expected order OR is not the expected segement list')
end

%Get numbers: Lenda day long data
%[It would be more elegant to functionalise some of this but it's just a few lines of code and I can't be botherd].
Lday_ReqAgeSubStruct = LdayStruct(ismember([LdayStruct.InfAgeMos],[3 6 9 18])); %pick out only required ages
LdayTotDur_s = sum([Lday_ReqAgeSubStruct.TotDurOfRec_Secs]); %get total duration of all daylong recs in dataset
%get silence and key seg duration totals: LENA day long data
LdayTotSIL_s = LdayTab.TotDur_s_DataLvl(strcmp(LdayTab.SegmentLabels,'SIL'));
LdayTotCHNSP_s = LdayTab.TotDur_s_DataLvl(contains(LdayTab.SegmentLabels,'CHNSP'));
LdayTotCHNNSP_s = LdayTab.TotDur_s_DataLvl(contains(LdayTab.SegmentLabels,'CHNNSP'));
LdayTotAN_s = sum(LdayTab.TotDur_s_DataLvl(contains(LdayTab.SegmentLabels,{'MAN','FAN'})));
LdayTotKeySegs_s = LdayTotCHNSP_s + LdayTotCHNNSP_s + LdayTotAN_s;

%Get numbers: validation data
TotL5minDur_s = sum([L5minStruct.TotFileDur_Secs]); %get total duration of all validation data in dataset
TotH5minDur_s = sum([H5minStruct.TotFileDur_Secs]);
TotH5min_TAd_Dur_s = sum([H5min_TAdStruct.TotFileDur_Secs]);

if ~isequal(TotH5minDur_s,TotL5minDur_s) %check to make sure that 
    error('Human-labelled and corresponding LENA labelled validation data has different total duration of audio')
end

if ~isequal(TotH5minDur_s,TotH5min_TAd_Dur_s) %check to make sure that 
    error('Human-labelled All-Ad and T-Ad data has different total duration of audio')
end

%Get total duration of key segments, one at a time
for i = 1:numel(KeySegs)
    L5minTot_Seg_i_sec(i) = sum(arrayfun(@(S)S.TotDurOfSegInRec_Secs(i),L5minStruct)); %This basically applies S.TotDurOfSegInRec_Secs(i) for every element in the L5min data structure
    H5minTot_Seg_i_sec(i) = sum(arrayfun(@(S)S.TotDurOfSegInRec_Secs(i),H5minStruct)); %similarly for human labelled data
    H5min_TAd_Tot_Seg_i_sec(i) = sum(arrayfun(@(S)S.TotDurOfSegInRec_Secs(i),H5min_TAdStruct)); %similarly for human labelled data, child-dir adult only 
end
    
%get total duration of all key segments together
L5minTotKeySegs_s = sum(L5minTot_Seg_i_sec); H5minTotKeySegs_s = sum(H5minTot_Seg_i_sec); H5min_TAd_TotKeySegs_s = sum(H5min_TAd_Tot_Seg_i_sec);

%print the numbers
sprintf(['Total duration of SIL in day long recordings summed over the entire  dataset (for 3, 6, 9, and 18 mos only) \n is %0.2f seconds (%0.2f hours); ' ...
        '%0.2f%% of total day-long audio duration'], ...
        LdayTotSIL_s,LdayTotSIL_s/60/60,LdayTotSIL_s/LdayTotDur_s*100)

%get mean, std, min, and max day-long recording durs
LdayMeanRecLength_hr = mean([Lday_ReqAgeSubStruct.TotDurOfRec_Secs])/60/60;
LdayStdRecLength_hr = std([Lday_ReqAgeSubStruct.TotDurOfRec_Secs])/60/60;
LdayMinRecLength_hr = min([Lday_ReqAgeSubStruct.TotDurOfRec_Secs])/60/60;
LdayMaxRecLength_hr = max([Lday_ReqAgeSubStruct.TotDurOfRec_Secs])/60/60;

ValData_TotNumSegs = round(TotL5minDur_s/60/5); %this rounding is because there is one section that is 3 minutes long 

sprintf(['For LENA day-long recordings: \n' ...
    'mean recording length = %0.2f hours \n' ...
    'std dev. or recording length = = %0.2f hours \n' ...
    'minimum recording length = %0.2f hours \n' ...
    'maximum recording length = %0.2f hours'],LdayMeanRecLength_hr,LdayStdRecLength_hr,LdayMinRecLength_hr,LdayMaxRecLength_hr)
sprintf('For validation data, there are a total of %i five-minute sections',ValData_TotNumSegs)

DataType = {'L-day','L5min','H5min','H5min_T-Ad'}';
TotAudioDur_s = [LdayTotDur_s; TotL5minDur_s; TotH5minDur_s; TotH5min_TAd_Dur_s];
TotAudioDur_hr = [LdayTotDur_s/60/60; TotL5minDur_s/60/60; TotH5minDur_s/60/60; TotH5min_TAd_Dur_s/60/60];
TotKeySegDur_s = [LdayTotKeySegs_s ; L5minTotKeySegs_s; H5minTotKeySegs_s; H5min_TAd_TotKeySegs_s];
TotKeySegDur_hr = [LdayTotKeySegs_s/60/60 ; L5minTotKeySegs_s/60/60; H5minTotKeySegs_s/60/60; H5min_TAd_TotKeySegs_s/60/60];
PercKeySegDurInTotAudio = TotKeySegDur_hr./TotAudioDur_hr*100;

OpTab = table(DataType,TotAudioDur_s,TotAudioDur_hr,TotKeySegDur_s,TotKeySegDur_hr,PercKeySegDurInTotAudio);
cd('~/BaseDataPath/Data/MetadataFiles')
writetable(OpTab,'TotAudioLengthAndKeySegPropDur.csv')
