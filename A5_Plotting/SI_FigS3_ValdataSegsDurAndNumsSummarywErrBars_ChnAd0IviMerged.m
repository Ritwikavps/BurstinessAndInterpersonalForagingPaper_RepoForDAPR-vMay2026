clear; clc
%@author info; plots mean, median, max and min duration of segment labels and mean, median, max and min number of segments at the recording day level for Validation 
% data. Based on 0 ivi merged segments for CHNSP, CHNNSP and AN (FAN/MAN treated as a single category) and all others not 0 Ivi merged. Only recordings at 3, 6, 9, 
% or 18 months included. This is specifically for the SI of the Burstiness paper draft. Note that, in the case of human-listener labelled data, we are using data that has
% been processed for overlaps and all overlaps have been removed. 

cd('~/BaseDataPath/Data/ResultsTabs/DataDescriptionSummaries')
L5_DurTab = readtable('L5minSegmentLevelDurationSummaryStats_0IviMerged_ChnAdOnly.csv');
H5_AllAdDurTab = readtable('H5min-AllAdSegmentLevelDurationSummaryStats_0IviMerged_ChnAdOnly.csv');
H5_TAdDurTab = readtable('H5min-TAdSegmentLevelDurationSummaryStats_0IviMerged_ChnAdOnly.csv');
L5_NumTab = readtable('L5minRecDayLevelSegmentNumsSummaryStats_0IviMerged_ChnAdOnly.csv');
H5_AllAdNumTab = readtable('H5min-AllAdRecDayLevelSegmentNumsSummaryStats_0IviMerged_ChnAdOnly.csv');
H5_TAdNumTab = readtable('H5min-TAdRecDayLevelSegmentNumsSummaryStats_0IviMerged_ChnAdOnly.csv');


%chekcs
if ~isequal(H5_AllAdDurTab.SegmentLabels,L5_DurTab.SegmentLabels)
    error('List of segment labels are not the same for H5 and L5 (duration tab)')
end

if ~isequal(H5_AllAdNumTab.SegmentLabels,L5_NumTab.SegmentLabels)
    error('List of segment labels are not the same for H5 and L5 (numbers tab)')
end

if ~isequal(H5_AllAdNumTab.SegmentLabels,H5_AllAdDurTab.SegmentLabels)
    error('List of segment labels are not the same for H5 duration and numbers tables')
end

if ~isequal(H5_AllAdNumTab.SegmentLabels,H5_TAdNumTab.SegmentLabels)
    error('List of segment labels are not the same for H5 All-Ad and H5 T-Ad numbers tables')
end

if ~isequal(H5_TAdDurTab.SegmentLabels,H5_TAdNumTab.SegmentLabels)
    error('List of segment labels are not the same for H5 T-Ad numbers and duration tables')
end

Segs_XTix = H5_AllAdDurTab.SegmentLabels; %get list of segments for x tick labels
Segs_XTix(strcmp(Segs_XTix,'CHNSP')) = {'ChSp'}; %recast segment labels
Segs_XTix(strcmp(Segs_XTix,'CHNNSP')) = {'ChNsp'};
Segs_XTix(strcmp(Segs_XTix,'AN')) = {'Ad'};

if ~strcmp(Segs_XTix{end},'Ad')
    error('Adult is not the third segment label. Code needs to be adjusted')
end

Xvals_L5 = (1:numel(Segs_XTix))-0.2; %get x values to plot for L5
%get x values to plot for H5; the third segemnt is 'adult' and we add data for H_T-Ad data, so we need this to be ordered such that L5 is at -0.2, 
% H5 is at the same x val, and H5_T-Ad is at +0.2
Xvals_H5 = (1:numel(Segs_XTix))+0.2; Xvals_H5(end) = Xvals_H5(end)-0.2;
Xvals_H5TAd = Xvals_H5(end) + 0.2; %shifting the first two x vals doesnt matter because we won't be plotting anyting for CHNSP and CHNNSP
L5Clr = [0 0 0]; H5Clr = [0 170 0]/256; H5_TAd_Clr = [0 0.4470 0.7410]; %colours

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLOTTING: I) Mean number of all sound types with error bars (mean taken over total number of each seg type at the recording level).
%-----------------------------------------------------------------------------------------------------
% Plot for mean segment number (across the whole dataset) for each segment type (mean taken over number of a given segment type for each day-long recording, for the entire dataset), 
% with error bars given by min and max durations. Median duration for each segment type plotted as a square. 

figure1 = figure('PaperType','<custom>','PaperSize',[18 8.5],'Color',[1 1 1]);
axes1_Nums = axes('Parent',figure1,'Position',[0.0969497373992581 0.236133122028526 0.385873015873016 0.712748667108853]); 
hold(axes1_Nums,'on');

%plotting for legend
plot([NaN NaN],[1 2],'Color',H5Clr,'LineWidth',2)
plot([NaN NaN],[1 2],'Color',H5_TAd_Clr,'LineWidth',2); 
plot([NaN NaN],[1 2],'Color',L5Clr,'LineWidth',2) 
plot(NaN,1,'Marker','o','MarkerFaceColor','k','LineStyle','none','MarkerEdgeColor','none','MarkerSize',8) %mean
plot(NaN,1,'Marker','square','MarkerFaceColor',[1 1 1],'LineStyle','none','MarkerEdgeColor','k','LineWidth',1) %median

PlotDurAndNumsErrorBars_ValData(H5_AllAdNumTab.MeanNum,H5_AllAdNumTab.MinNum,H5_AllAdNumTab.MaxNum,H5_AllAdNumTab.MedianNum,Xvals_H5,H5Clr) %H5
PlotDurAndNumsErrorBars_ValData(H5_TAdNumTab.MeanNum(end),H5_TAdNumTab.MinNum(end),...
    H5_TAdNumTab.MaxNum(end),H5_TAdNumTab.MedianNum(end),Xvals_H5TAd,H5_TAd_Clr) %H5 T-Ad
PlotDurAndNumsErrorBars_ValData(L5_NumTab.MeanNum,L5_NumTab.MinNum,L5_NumTab.MaxNum,L5_NumTab.MedianNum,Xvals_L5,L5Clr) %L5

%do the rest of the plot
ylabel('Number of segments in recording'); title('A'); xlabel('Segment label');
xlim(axes1_Nums,[0.5 3.5]); %ylim(axes1_Nums,[-30 9100]); 
hold(axes1_Nums,'off');
set(axes1_Nums,'FontSize',24,'XGrid','on','XTick',[1 2 3],'XTickLabel',Segs_XTix,'YGrid','on','YMinorGrid','on','Box','on');
legend({'H (5min)','H (5min; T-Ad)','L (5min)','Mean','Median'},...
    'Position',[0.287768962048947 0.832249792435182 0.186258935663225 0.0956006768189509],'Orientation','horizontal');

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLOTTING: II) Mean duration of all sound types with error bars (mean across all segs of each type).
%----------------------------------------------------------------------------------------------------
% Plot for mean segment duration (across the whole dataset) for each segment type (mean taken over all segment durations of a given type across the entire data set), with error bars
% given by min and max durations. Median duration for each segment type plotted as a square. 

axes1_Dur = axes('Parent',figure1,'Position',[0.606500001949523 0.236133122028526 0.385873015873016 0.712748667108853]); 
hold(axes1_Dur,'on');

PlotDurAndNumsErrorBars_ValData(H5_AllAdDurTab.MeanDur_s,H5_AllAdDurTab.MinDur_s,H5_AllAdDurTab.MaxDur_s,H5_AllAdDurTab.MedianDur_s,Xvals_H5,H5Clr) %H5
PlotDurAndNumsErrorBars_ValData(H5_TAdDurTab.MeanDur_s(end),H5_TAdDurTab.MinDur_s(end),H5_TAdDurTab.MaxDur_s(end),...
                                    H5_TAdDurTab.MedianDur_s(end),Xvals_H5TAd,H5_TAd_Clr) %H5 T-Ad
PlotDurAndNumsErrorBars_ValData(L5_DurTab.MeanDur_s,L5_DurTab.MinDur_s,L5_DurTab.MaxDur_s,L5_DurTab.MedianDur_s,Xvals_L5,L5Clr) %L5

%do the rest of the plot
ylabel('Duration (s)'); xlabel('Segment label'); title('B');
xlim(axes1_Dur,[0.5 3.5]); %ylim(axes1_Dur,[0.009 12000]); 
hold(axes1_Dur,'off');
set(axes1_Dur,'FontSize',24,'XGrid','on','XTick',[1 2 3 4],'XTickLabel',Segs_XTix,'YGrid','on','YMinorGrid','on','Box','on');

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%Functions used
%----------------------------------------------------------------------------------------------------
%This function takes in list of unique segment labels (UniqSegs) as well as mean, min and max values for sound duration/number of different segment labels and plots error bars. 
% Order of segment labels in mean, min etc. vectors corresponds to order in UniqSegs. Also plots the median values separately.
% Also takes in indices for key segments (CHNSP, CHNNSP, FAN, MAN), Near segments, and SIL segemnt, as well as colour labels for all segment labels (OtherSegClr), Key segments, and SIL.
function [] = PlotDurAndNumsErrorBars_ValData(MeanVals,MinVals,MaxVals,MedianVals,Xvals,Clr)

    %plot all means sorted in incresing order of mean value (here, this is the first layer, which is dashed. We will plot the {CHNSP, CHNNSP, MAN, FAN} sounds as red, all other
    % near type sounds as solid error bar lines, and silence as grey, on top of this base dashed lines).
    d = errorbar(Xvals,MeanVals, ...
        abs(MinVals-MeanVals),abs(MaxVals-MeanVals),...
        'MarkerFaceColor',Clr,'Marker','o','LineStyle','none','LineWidth',2,'MarkerEdgeColor','none','Color',Clr,'MarkerSize',8);
    plot(Xvals,MedianVals,'MarkerFaceColor',[1 1 1],'MarkerSize',7,'Marker','square','LineWidth',1,'LineStyle','none','MarkerEdgeColor',Clr);
end