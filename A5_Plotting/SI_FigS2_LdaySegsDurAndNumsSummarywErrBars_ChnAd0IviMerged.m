clear; clc
%@author info; plots mean, median, max and min duration of segment labels and mean, median, max and min number of segments at the recording day level for LENA day long data. Based on 
% 0 ivi merged segments for CHNSP, CHNNSP and AN (FAN/MAN treated as a single category) and all others not 0 Ivi merged. Only recordings at 3, 6, 9, or 18 months included. This is 
% specifically for the SI of Burstiness paper draft. 

cd('~/BaseDataPath/Data/ResultsTabs/DataDescriptionSummaries')
IpTab = readtable('LdaySegDurAndNumsSummaryStats_ChnAd0IviMerged.xlsx','Sheet','FullTable');

%get segment indices for each class of segment labels
SegLabels = IpTab.SegmentLabels; Idx = 1:numel(SegLabels);
KeySegs = {'CHNSP','CHNNSP','AN'};
for i = 1:numel(KeySegs)
    KeySegInds(i) = Idx(strcmp(SegLabels,KeySegs{i})); %CHNSP, CHNNSP, AN
end
SIL_Ind = Idx(contains(SegLabels,'SIL'));
NearSegInds = Idx(contains(SegLabels,{'N'}) & ~contains(SegLabels,'F')); 

Segs_XTix = SegLabels;
Segs_XTix(strcmp(Segs_XTix,'CHNSP')) = {'ChSp'};
Segs_XTix(strcmp(Segs_XTix,'CHNNSP')) = {'ChNsp'};
Segs_XTix(strcmp(Segs_XTix,'AN')) = {'Ad'};

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
PlotDurAndNumsErrorBars(SegLabels,IpTab.MeanDur_s_SegLvl,IpTab.MinDur_s_SegLvl,IpTab.MaxDur_s_SegLvl,IpTab.MedianDur_s_SegLvl,...
            KeySegInds,SIL_Ind,NearSegInds,OtherSegClr,KeySegClr,SILClr);

%do the rest of the plot
ylabel('Duration (s)','Position',[-1.193090909090909 10.392374733132382 -1]); 
xlabel('LENA segment label','Position',[8.500007629394531 0.001094817639155 -1]); title('B','Position',[-0.867263190529563 11815.73758027616 0]);
ylim(axes1_Dur,[0.009 12000]); xlim(axes1_Dur,[0.5 15.5]);
hold(axes1_Dur,'off');
set(axes1_Dur,'FontSize',24,'XGrid','on','XTick',[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15],...
    'XTickLabel',Segs_XTix,'XTickLabelRotation',90,'YGrid','on','YScale','log','YMinorGrid','on','Box','on');

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLOTTING: II) Mean number of all sound types with error bars (mean taken over total number of each seg type at the recording level).
%-----------------------------------------------------------------------------------------------------
% Plot for mean segment number (across the whole dataset) for each segment type (mean taken over number of a given segment type for each day-long recording, for the entire dataset), 
% with error bars given by min and max durations. Median duration for each segment type plotted as a square. Different colour/line stype codes for key segment types 
% (CHNSP, CHNNSP, FAN, MAN), all other near segement types, and silence.
axes1_Nums = axes('Parent',figure1,'Position',[0.0903174603174603 0.166431331336042 0.385873015873016 0.815]); 
hold(axes1_Nums,'on');
PlotDurAndNumsErrorBars(SegLabels,IpTab.MeanNumSegs_RecLvl,IpTab.MinNumSegs_RecLvl,IpTab.MaxNumSegs_RecLvl,IpTab.MedianNumSegs_RecLvl,...
            KeySegInds,SIL_Ind,NearSegInds,OtherSegClr,KeySegClr,SILClr);

%do the rest of the plot
ylabel('Number of segments in recording','Position',[-1.35204847085978 4485.00430583954 -1]); 
title('A','Position',[-1.212627091713191 8990.092476489019 0]); xlabel('LENA segment label','Position',[8.500007629394531 -1378.838557993729 -1]);
ylim(axes1_Nums,[-30 9100]); xlim(axes1_Nums,[0.5 15.5]);
hold(axes1_Nums,'off');
set(axes1_Nums,'FontSize',24,'XGrid','on','XTick',[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15],'XTickLabel',Segs_XTix,'XTickLabelRotation',90,...
    'YTick',[0 1500 3000 4500 6000 7500 9000],'YTickLabel',{'0','1500','3000','4500','6000','7500','9000'},'YGrid','on','YMinorGrid','on','Box','on');
legend({'Target child or adult (near)','All other near (N) sounds','All far (F) sounds','Silence','Mean','Median'},...
    'Position',[0.141228281853282 0.738509316770186 0.292162698412698 0.201863354037267]) %legend

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

    %plotting CHNSP, CHNNSP, AN
    errorbar(KeySegInds,MeanVals(KeySegInds), ...
        abs(MinVals(KeySegInds)-MeanVals(KeySegInds)),abs(MaxVals(KeySegInds)-MeanVals(KeySegInds)),...
        'MarkerFaceColor',KeySegClr,'Marker','o','LineStyle','none','LineWidth',2,'MarkerEdgeColor','none','Color',KeySegClr,'MarkerSize',8);
    semilogy(KeySegInds,MedianVals(KeySegInds),'MarkerFaceColor',[1 1 1],'MarkerSize',7,'Marker','square','LineWidth',1,'LineStyle','none','Color',KeySegClr);
end