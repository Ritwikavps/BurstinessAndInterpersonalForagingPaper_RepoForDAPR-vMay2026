clear; clc

%Get summary stats (mean, median, etc) for durations of all LENA segment labels in day long data, as well as for number of segements at teh recording level. Summary stats are computed
% across all day-long recordings. 
% Also, saves relevant tables with this info as well as plots figures (note that these figure do not report voc numbers for CHNSP, CHNNSP, and AN vocs *after* 0 s IEI merging, and
% therefore are not relevant to or reported in the Burstiness paper/pre-print (2025). For the figures reported in the Burstiness paper, see relevant plotting code in the folder
% with code for plots).
% Note that this is for the data paper, and uses segment labels without merging segments of the same type which have 0 IVI *and* treats MAN/MAF and FAN/FAF as two separate label
% categories vs a single adult (Ad) category.
% Also note that these duration and number summaries exclude recordings at ages other than 3, 6, 9, and 18 mos while the .mat file saved does contain info about files also at 
% ages other than 3, 6, 9, and 18 months. 

%read in LENA day-long metadata
Basepath = '~/BaseDataPath/';
LdayMetaDataPath = strcat(Basepath,'Data/MetadataFiles/');
cd(LdayMetaDataPath)
opts = detectImportOptions('MergedTSAcousticsMetadata.csv'); %make sure to read in infant code as string, so get options to read the file
opts = setvartype(opts, 'InfantID', 'string'); %set up opts so that infant id is read in as string
LdayMetadataTab = readtable('MergedTSAcousticsMetadata.csv',opts); %read in file with updated options

%read in LENA segemnts (with time series and label info for all LENA segment types)
LdaySegmentsPath = strcat(Basepath,'Data/LENAData/A2_Segments/');
cd(LdaySegmentsPath)
LdaySegs = dir('*_Segments.csv');

TabForUniqSegs = readtable(LdaySegs(1).name); %read the first of these segment files to get a list of unqiue segment labels
%can test this against the LENA technical report to make sure that all segments are represented
UniqSegs = unique(TabForUniqSegs.segtype); %get list of unique segment labels
if isequal(sort({'CHNSP','CHNNSP','CHF','FAN','FAF','MAN','MAF','CXN','CXF','OLN','OLF','TVN','TVF','NON','NOF','SIL'}),sort(UniqSegs'))
    UniqSegs = {'CHNSP','CHNNSP','CHF','FAN','FAF','MAN','MAF','CXN','CXF','OLN','OLF','TVN','TVF','NON','NOF','SIL'}'; %prescribed order for plotting
else
    error('Prescribed order of segment labels does not have all segment labels')
end

%get indices corresponding to infant and adult utterance segment labels
SegsInd = 1:numel(UniqSegs);  %get vector of indices
SIL_Ind = SegsInd(strcmp(UniqSegs,'SIL')); %get index for silence label
KeySegInds = SegsInd(ismember(UniqSegs,{'CHNSP','CHNNSP','MAN','FAN'})); %get indices corresponding to CHNSP, CHNNSP, MAN, and FAN
KeySegLabels = UniqSegs(KeySegInds); %extract those labels from the segment label vector (to get them in the same order as the order corresponding to ReqInds)
NearSegLabels = UniqSegs(contains(UniqSegs,'N') & ~contains(UniqSegs,KeySegLabels) & ~contains(UniqSegs,'F')); %get list of near segment labels
NearSegInds = SegsInd(ismember(UniqSegs,NearSegLabels)); %get corresponding indices
NearSegLabels = UniqSegs(NearSegInds); %re-sort to make sure that indices and labels are in gthe same order as each other

for i = 1:numel(LdaySegs) %go through list of segment files to get file name
    Fname_SubrecLvl{i,1} = regexprep(LdaySegs(i).name(1:12),'_$',''); %get the file name; picks out first 12 characters, which can be like 0009_000302_ or 0009_000302a. In the former case,
    %we want to remove the '_', ergo the use of regexprep. Note that this is because we have not yet merged the subrecordings in cases where a day-long recording has been split into 
    % sub-recordings due to deletions.  
end

FnameInd_SubrecLvl = 1:numel(Fname_SubrecLvl); %get index vector corresponding to teh list of (sub-recording level, when applicable) file names

%FnameInd gives indices corresponding to segments file names, where these file names are at the level of the sub-recordings. That is, if a day-long recording is split into two subrecs, 
% a and b, the files names for teh segments files reflect that. The metadata file  describes the data at the day-long recording level, and we will be reporting aspects of the
% data at the day-long recoridng level as well, for the LENA day-long data. Below, the for loop takes info at teh sub-recording level and compiles them at the day-long recording level, 
% where applicable.
for i = 1:numel(LdayMetadataTab.FileNameRoot) %go through list of file names from metadata table
    FnameIndSubset = FnameInd_SubrecLvl(contains(Fname_SubrecLvl,LdayMetadataTab.FileNameRoot{i})); %get indices corresponding to a day-long file (will include indices corresponding to sub-recs of 
    %a day-long file)
    SegsDur = cell(1,numel(UniqSegs));
    for j = 1:numel(FnameIndSubset) %go through list of indices for the file name
        CurrTab = readtable(LdaySegs(FnameIndSubset(j)).name); %read in table
        for k = 1:numel(UniqSegs)
            SubTab = CurrTab(strcmp(CurrTab.segtype,UniqSegs{k}),:);
            SegsDur{k} = [SegsDur{k}; SubTab.endsec - SubTab.startsec];
        end
    end
   
    DurStruct(i).TotDurOfSegInRec_Secs = cellfun(@sum,SegsDur); %store total duration of each segment type at the recording level in the structure
    DurStruct(i).TotNumOfSegInRec = cellfun(@numel,SegsDur); %store total numbers of each segment type at the recording level in the structure
    DurStruct(i).TotDurOfRec_Secs = sum(DurStruct(i).TotDurOfSegInRec_Secs); %add duration of day long recording to the vector storing this info for each day-long recording; this is simply the sum
    %of durations of all segments in the recording
    DurStruct(i).DurOfSegments = SegsDur; %SegsDur is cell array where kth element is a vector of durations of all segments of type k in the recording
    DurStruct(i).InfID = LdayMetadataTab.InfantID{i};
    DurStruct(i).InfAgeMos = LdayMetadataTab.InfantAgeMonth(i);
end

DurStruct(1).SegsList = UniqSegs; %store list of segments

%get duration mean, median, max, and min for all ages together, for all segment labels.
for i = 1:numel(UniqSegs)
    TempDurVec = [];
    for j = 1:numel(DurStruct)
        if ismember(DurStruct(j).InfAgeMos,[3 6 9 18]) %only proceed if age is 3, 6, 9, or 18 mos. If not, do not add to summary duration and number stats computation
            TempDurVec = [TempDurVec; DurStruct(j).DurOfSegments{i}];
        end
    end
    MeanDurSegs_SegLvl(i,1) = mean(TempDurVec,'omitnan');
    StdDurSegs_SegLvl(i,1) = std(TempDurVec,'omitnan');
    MinDurSegs_SegLvl(i,1) = min(TempDurVec);
    MaxDurSegs_SegLvl(i,1) = max(TempDurVec);
    MedianDurSegs_SegLvl(i,1) = median(TempDurVec);
    TotDurSegs_DataLvl(i,1) = sum(TempDurVec);
end

%Get mean number of different segs at the rec level.
for i = 1:numel(UniqSegs) %go through list of un ique segemnt labels
    TempNumVec = [];
    for j = 1:numel(DurStruct) %go through struct
        if ismember(DurStruct(j).InfAgeMos,[3 6 9 18]) %only proceed if age is 3, 6, 9, or 18 mos. If not, do not add to summary duration and number stats computation
            TempNumVec = [TempNumVec; DurStruct(j).TotNumOfSegInRec(i)]; %pull out tot number of segment label i in each structure element cell array
        end
    end
    MeanNumSegs_RecLvl(i,1) = mean(TempNumVec,'omitnan'); %get stat numbers
    StdNumSegs_RecLvl(i,1) = std(TempNumVec,'omitnan');
    MinNumSegs_RecLvl(i,1) = min(TempNumVec);
    MaxNumSegs_RecLvl(i,1) = max(TempNumVec);
    MedianNumSegs_RecLvl(i,1) = median(TempNumVec);
    TotNumSegs_DataLvl(i,1) = sum(TempNumVec);
end

%table with decriptive stats for duration: mean, median etc duration of each segemnt type (calculated across the entire data set) + total duration of each segementlabel type at the 
% dataset level.
SegLvlDurStatsTab = table(UniqSegs,MeanDurSegs_SegLvl,StdDurSegs_SegLvl,MedianDurSegs_SegLvl,MaxDurSegs_SegLvl,MinDurSegs_SegLvl,TotDurSegs_DataLvl);
SegLvlDurStatsTab.Properties.VariableNames = {'SegmentLabels','MeanDur_s','StdDevDur_s','MedianDur_s','MaxDur_s','MinDur_s','TotDur_s_DataLvl'};

%table with decriptive stats for number of segment labels: mean, median etc number of each segemnt type at the recording level (calculated across the entire data set). That is,
% we compute the total number of each segemnt type in each recording and then get the mean, median etc of the number of this distribution + total duration of each segementlabel 
% type at the dataset level.
RecLvlSegNumStatsTab = table(UniqSegs,MeanNumSegs_RecLvl,StdNumSegs_RecLvl,MedianNumSegs_RecLvl,MaxNumSegs_RecLvl,MinNumSegs_RecLvl,TotNumSegs_DataLvl);
RecLvlSegNumStatsTab.Properties.VariableNames = {'SegmentLabels','MeanNum','StdDevNum','MedianNum','MaxNum','MinNum','TotNum_DataLvl'};

%destination to write
Destinationpath = strcat(Basepath,'Data/ResultsTabs/DataDescriptionSummaries/');
cd(Destinationpath)
writetable(SegLvlDurStatsTab,'LdaySegmentLevelDurationSummaryStats_No0IviMerge.csv')
writetable(RecLvlSegNumStatsTab,'LdayRecDayLevelSegmentNumsSummaryStats_No0IviMerge.csv')
save('LdaySegsDurStruct_No0IviMerged.mat','DurStruct')

%recast segement labels for X ticks (CHNSP to ChSp and CHNNSP to ChNsp)
UniqSegs_XTix = UniqSegs;
UniqSegs_XTix(strcmp(UniqSegs_XTix,'CHNSP')) = {'ChSp'};
UniqSegs_XTix(strcmp(UniqSegs_XTix,'CHNNSP')) = {'ChNsp'};

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLOTTING: I) Mean duration of all sound types with error bars (mean across all segs of each type).
%-----------------------------------------------------------------------------------------------------
KeySegClr = [0.85 0.15 0.15];
SILClr = [0.64 0.64 0.64];
OtherSegClr = [0 0 0];

% Plot for mean segment duration (across the whole dataset) for each segment type (mean taken over all segment durations of a given type across the entire data set), with error bars
% given by min and max durations. Median duration for each segment type plotted as a square. Different colour/line stype codes for key segment types (CHNSP, CHNNSP, FAN, MAN), all 
% other near segement types, and silence.

figure1 = figure('PaperType','<custom>','PaperSize',[21.5 10.5],'Color',[1 1 1]);
axes1_Dur = axes('Parent',figure1,'Position',[0.599867724867725 0.166431331336042 0.385873015873016 0.815]); 
hold(axes1_Dur,'on');
PlotDurAndNumsErrorBars(UniqSegs,MeanDurSegs_SegLvl,MinDurSegs_SegLvl,MaxDurSegs_SegLvl,MedianDurSegs_SegLvl,...
            KeySegInds,SIL_Ind,NearSegInds,OtherSegClr,KeySegClr,SILClr);

%do the rest of the plot
ylabel('Duration (s)','Position',[-1.193090909090909 10.392374733132382 -1]); 
xlabel('LENA segment label','Position',[8.500007629394531 0.001094817639155 -1]); title('B','Position',[-0.867263190529563 11815.73758027616 0]);
ylim(axes1_Dur,[0.009 12000]); xlim(axes1_Dur,[0.5 16.5]);
hold(axes1_Dur,'off');
set(axes1_Dur,'FontSize',24,'XGrid','on','XTick',[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16],...
    'XTickLabel',UniqSegs_XTix,'XTickLabelRotation',90,'YGrid','on','YScale','log','YMinorGrid','on','Box','on');

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLOTTING: II) Mean number of all sound types with error bars (mean taken over total number of each seg type at the recording level).
%-----------------------------------------------------------------------------------------------------
% Plot for mean segment number (across the whole dataset) for each segment type (mean taken over number of a given segment type for each day-long recording, for the entire dataset), 
% with error bars given by min and max durations. Median duration for each segment type plotted as a square. Different colour/line stype codes for key segment types 
% (CHNSP, CHNNSP, FAN, MAN), all other near segement types, and silence.
axes1_Nums = axes('Parent',figure1,'Position',[0.0903174603174603 0.166431331336042 0.385873015873016 0.815]); 
hold(axes1_Nums,'on');
PlotDurAndNumsErrorBars(UniqSegs,MeanNumSegs_RecLvl,MinNumSegs_RecLvl,MaxNumSegs_RecLvl,MedianNumSegs_RecLvl,...
            KeySegInds,SIL_Ind,NearSegInds,OtherSegClr,KeySegClr,SILClr);

%do the rest of the plot
ylabel('Number of segments in recording','Position',[-1.35204847085978 4485.00430583954 -1]); 
title('A','Position',[-1.212627091713191 8990.092476489019 0]); xlabel('LENA segment label','Position',[8.500007629394531 -1378.838557993729 -1]);
ylim(axes1_Nums,[-30 9100]); xlim(axes1_Nums,[0.5 16.5]);
hold(axes1_Nums,'off');
set(axes1_Nums,'FontSize',24,'XGrid','on','XTick',[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16],'XTickLabel',UniqSegs_XTix,'XTickLabelRotation',90,...
    'YTick',[0 1500 3000 4500 6000 7500 9000],'YTickLabel',{'0','1500','3000','4500','6000','7500','9000'},'YGrid','on','YMinorGrid','on','Box','on');
legend({'Target child or adult (near)','All other near (N) sounds','All far (F) sounds','Silence','Mean','Median'},...
    'Position',[0.141228281853282 0.738509316770186 0.292162698412698 0.201863354037267]) %legend

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLOTTING: III) Histograms for total duration and numbers of segments.
%-----------------------------------------------------------------------------------------------------
figure1 = figure('PaperType','<custom>','PaperSize',[14.5 11.5],'Color',[1 1 1]);
axes1 = axes('Parent',figure1,'Position',[0.129363509333835 0.160248447204969 0.853887722193254 0.792546583850932]); hold(axes1,'on');
   
bar1 = bar(UniqSegs,[TotNumSegs_DataLvl TotDurSegs_DataLvl]);
set(bar1(1),'EdgeColor','none','FaceColor',[178 24 43]/256);
set(bar1(2),'EdgeColor','none','FaceColor',[33 102 172]/256)

ylim(axes1,[0 2150000.29]); 
ylabel('Total duration (s)/number of segments','Position',[-1.296431472918087 1055275.13138783 -1]); 
title('B','Position',[-0.835401305989997 2108232.601405956 0]); 
xlabel('LENA segment label','Position',[8.500007956581536 -315259.0157319747 -1]);
set(axes1,'FontSize',24,'XGrid','off','XTickLabel',UniqSegs_XTix,'XTickLabelRotation',90,'YGrid','on','YMinorGrid','on','Box','on','TickDir','none');
legend({'Total number of segments','Total duration of segments (s)'},'Position',[0.140430295700071 0.870186320383051 0.325074331020813 0.070186335403727]) %legend

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%Functions used
%----------------------------------------------------------------------------------------------------
%This function takes in list of unique segment labels (UniqSegs) as well as mean, min and max values for sound duration/number of different segment labels and plots error bars. 
% Order of segment labels in mean, min etc. vectors corresponds to order in UniqSegs. Also plots the median values separately.
% Also takes in indices for key segments (CHNSP, CHNNSP, FAN, MAN), Near segments, and SIL segemnt, as well as colour labels for all segment labels (OtherSegClr), Key segments, and SIL.
function [] = PlotDurAndNumsErrorBars(UniqSegs,MeanVals,MinVals,MaxVals,MedianVals,KeySegInds,SIL_Ind,NearSegInds,OtherSegClr,KeySegClr,SILClr)
    
    %plotting for legend
    plot([NaN NaN],[1 2],'Color',KeySegClr,'LineWidth',2) %CHNSP, CHNNSP, MAN, FAN
    plot([NaN NaN],[1 2],'Color',OtherSegClr,'LineWidth',2) %all other near type sounds
    plot([NaN NaN],[1 2],'Color',OtherSegClr,'LineWidth',2,'LineStyle','--') %all far types
    plot([NaN NaN],[1 2],'Color',SILClr,'LineWidth',2) %SIL
    plot(NaN,1,'Marker','o','MarkerFaceColor','k','LineStyle','none','MarkerEdgeColor','none','MarkerSize',8) %mean
    plot(NaN,1,'Marker','square','MarkerFaceColor',[1 1 1],'LineStyle','none','MarkerEdgeColor','k','LineWidth',1) %median

    %plot all means sorted in incresing order of mean value (here, this is the first layer, which is dashed. We will plot the {CHNSP, CHNNSP, MAN, FAN} sounds as red, all other
    % near type sounds as solid error bar lines, and silence as grey, on top of this base dashed lines).
    d = errorbar(1:numel(UniqSegs),MeanVals, ...
        abs(MinVals-MeanVals),abs(MaxVals-MeanVals),...
        'MarkerFaceColor',OtherSegClr,'Marker','o','LineStyle','none','LineWidth',2,'MarkerEdgeColor','none','Color',OtherSegClr,'MarkerSize',8);
    d.Bar.LineStyle = 'dashed'; %set the error bar line style
    semilogy(1:numel(UniqSegs),MedianVals,'MarkerFaceColor',[1 1 1],'MarkerSize',7,'Marker','square','LineWidth',1,'LineStyle','none','MarkerEdgeColor',OtherSegClr);
    
    %plotting CHNSP, CHNNSP, MAN, FAN
    errorbar(KeySegInds,MeanVals(KeySegInds), ...
        abs(MinVals(KeySegInds)-MeanVals(KeySegInds)),abs(MaxVals(KeySegInds)-MeanVals(KeySegInds)),...
        'MarkerFaceColor',KeySegClr,'Marker','o','LineStyle','none','LineWidth',2,'MarkerEdgeColor','none','Color',KeySegClr,'MarkerSize',8);
    semilogy(KeySegInds,MedianVals(KeySegInds),'MarkerFaceColor',[1 1 1],'MarkerSize',7,'Marker','square','LineWidth',1,'LineStyle','none','Color',KeySegClr);
    
    %plotting silence: we need the X axis co-ord, based on the sorted index, and then we need to get the relevany mean, which we can use the unsorted index.
    errorbar(SIL_Ind,MeanVals(SIL_Ind), ...
            abs(MinVals(SIL_Ind)-MeanVals(SIL_Ind)),abs(MaxVals(SIL_Ind)-MeanVals(SIL_Ind)),...
            'MarkerFaceColor',SILClr,'Marker','o','LineStyle','none','LineWidth',2,'MarkerEdgeColor','none','Color',SILClr,'MarkerSize',8);
    semilogy(SIL_Ind,MedianVals(SIL_Ind),'MarkerFaceColor',[1 1 1],'MarkerSize',7,'Marker','square','LineWidth',1,'LineStyle','none','Color',SILClr);
    
    %plot near segment labels
    errorbar(NearSegInds,MeanVals(NearSegInds), ...
        abs(MinVals(NearSegInds)-MeanVals(NearSegInds)),abs(MaxVals(NearSegInds)-MeanVals(NearSegInds)),...
        'MarkerFaceColor',OtherSegClr,'Marker','o','LineStyle','none','LineWidth',2,'MarkerEdgeColor','none','Color',OtherSegClr,'MarkerSize',8);
    semilogy(NearSegInds,MedianVals(NearSegInds),'MarkerFaceColor',[1 1 1],'MarkerSize',7,'Marker','square','LineWidth',1,'LineStyle','none','Color',OtherSegClr);
end