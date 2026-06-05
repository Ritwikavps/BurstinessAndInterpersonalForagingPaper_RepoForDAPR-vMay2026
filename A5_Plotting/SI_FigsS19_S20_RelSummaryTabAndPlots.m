%@author info; reliability plots
%This script generates tables with mean and total error rates for human listener labelled data where all adult utterances are considered and where only child-directed adult utterances
% are considered, against corresponding LENA labelled data. This script also generates total confusion matrices, and plots total precision and recalls for key segments
% for H (All Ad) and H (T-Ad) data. We use file level estimates for this.
clearvars; clc

%go to path
cd('~/BaseDataPath/Data/ResultsTabs/ReliabilityTabs/');

%load confusion matrices
ConfStructFromFile = load('ConfusionMatStruct.mat');
CM_Struct = ConfStructFromFile.ConfusionStruct;
CM_Struct_HAllAd = CM_Struct((ismember({CM_Struct.SecOrFileLvl},'file')) & (ismember({CM_Struct.HumAdultVocType},'All'))); %get H-AllAd and file level
CM_Struct_HTAd = CM_Struct((ismember({CM_Struct.SecOrFileLvl},'file')) & (ismember({CM_Struct.HumAdultVocType},'ChildDir'))); %get H-TAd and file level

%Get total confusion matrices + precision and recall for key segments.
[Tot_IntersectNums_HAllAd,TotPrec_KeySegs_HAllAd,TotRecall_KeySegs_HAllAd] = GetConfMatPrecAndRecallSummaries(CM_Struct_HAllAd);
[Tot_IntersectNums_HTAd,TotPrec_KeySegs_HTAd,TotRecall_KeySegs_HTAd] = GetConfMatPrecAndRecallSummaries(CM_Struct_HTAd);
LabelSet = {'ChSp','ChNsp','Ad','NA'}; %set of labels

%-----------------------------------------------------------------
%Plotting: confusion matrics (expressed as seconds, by dividing number of frames by 1000, cuz frames are 1 ms long).
figure1 = figure('PaperType','<custom>','PaperSize',[21.5 9.5],'Color',[1 1 1]);

%H All Ad confusion mat: scale by 1000 and round to express in seconds
h1 = heatmap(figure1,LabelSet,LabelSet,round(Tot_IntersectNums_HAllAd/1000),'InnerPosition',[0.0823809523809522 0.217333333333333 0.342883597883598 0.698754385964913],...
    'ColorScaling','log','GridVisible','off','Colormap',pink,'FontSize',22);
set(struct(h1).NodeChildren(3), 'YTickLabelRotation', 90);
annotation(figure1,'textbox',[0.037037037037036 0.898333333333331 0.0343915343915344 0.0553333333333333],'String',{'A'},'FontWeight','bold',...
    'FontSize',26,'FontName','Helvetica Neue','EdgeColor','none');
annotation(figure1,'textbox',[0.0291005291005275 0.403666666666662 0.173115079365079 0.0513333333333333],'String',{'Human listener labels'},...
    'Rotation',90,'FontSize',24,'EdgeColor','none');
annotation(figure1,'textbox',[0.740740740740737 0.0689999999999998 0.106646825396825 0.0513333333333333],'String',{'LENA labels'},'FontSize',24,'EdgeColor','none');
annotation(figure1,'textbox',[0.00198412698412698 0.965333333333333 0.0641534391534391 0.0266666666666669],'String',{'H All Ad'},'FitBoxToText','off');

%H T ad confusion mat and round to express in seconds
h2 = heatmap(figure1,LabelSet,LabelSet,round(Tot_IntersectNums_HTAd/1000),'InnerPosition',[0.612007575757571 0.217333333333333 0.342883597883598 0.698754385964913],...
    'ColorScaling','log','GridVisible','off','Colormap',pink,'FontSize',22);
set(struct(h2).NodeChildren(3), 'YTickLabelRotation', 90);
annotation(figure1,'textbox',[0.562830687830686 0.898333333333331 0.0347222222222222 0.0553333333333333],'String',{'B'},'FontWeight','bold',...
    'FontSize',26,'FontName','Helvetica Neue','EdgeColor','none');
annotation(figure1,'textbox',[0.558201058201055 0.403666666666664 0.173115079365079 0.0513333333333333],'String',{'Human listener labels'},...
    'Rotation',90,'FontSize',24,'EdgeColor','none');
annotation(figure1,'textbox',[0.203703703703703 0.0689999999999998 0.106646825396825 0.0513333333333333],'String',{'LENA labels'},'FontSize',24,'EdgeColor','none');

%-----------------------------------------------------------------
%Plotting: Key segments precision and recall.
figure1 = figure('PaperType','<custom>','PaperSize',[20 9],'Color',[1 1 1]);

%Precision
axes1 = axes('Parent',figure1,'Position',[0.101929824561403 0.175934065934066 0.371929824561403 0.748712715855574]); hold(axes1,'on');
plot((1:3)-0.1, TotPrec_KeySegs_HAllAd,'MarkerSize',35,'Marker','.','LineStyle','none')
plot((1:3)+0.1, TotPrec_KeySegs_HTAd,'MarkerFaceColor',[0.850980392156863 0.325490196078431 0.0980392156862745],...
    'MarkerEdgeColor',[0.850980392156863 0.325490196078431 0.0980392156862745],'MarkerSize',10,'Marker','square','LineStyle','none');
title('A'); ylabel('Precision'); xlabel('Segment label'); 
xlim(axes1,[0.8 3.2]); ylim(axes1,[0 1]);
hold(axes1,'off'); set(axes1,'FontSize',24,'XGrid','on','XTick',[1 2 3],'XTickLabel',{'ChSp','ChNsp','Ad'},'YGrid','on','YMinorGrid','on');
legend({'H (5min; All Ad)','H (5min; T-Ad)'})

%Recall
axes2 = axes('Parent',figure1,'Position',[0.611929824561402 0.175934065934067 0.371929824561402 0.748712715855574]); hold(axes2,'on');
plot((1:3)-0.1, TotRecall_KeySegs_HAllAd,'MarkerSize',35,'Marker','.','LineStyle','none')
plot((1:3)+0.1, TotRecall_KeySegs_HTAd,'MarkerFaceColor',[0.850980392156863 0.325490196078431 0.0980392156862745],...
    'MarkerEdgeColor',[0.850980392156863 0.325490196078431 0.0980392156862745],'MarkerSize',10,'Marker','square','LineStyle','none')
title('B'); ylabel('Recall'); xlabel('Segment label'); 
xlim(axes2,[0.8 3.2]); ylim(axes2,[0 1]);
hold(axes2,'off'); set(axes2,'FontSize',24,'XGrid','on','XTick',[1 2 3],'XTickLabel',{'ChSp','ChNsp','Ad'},'YGrid','on','YMinorGrid','on');
legend({'H (5min; All Ad)','H (5min; T-Ad)'})

%-----------------------------------------------------------------
%Agregate reliability numbers
RelMasterTab = readtable('ReliabilityErrorRates_FileOrSectionLvl.csv'); % read in table
%Get file level error rates for both H (T Ad) and H (All Ad). 
Rel_HAllAd_FileLvl = RelMasterTab(contains(RelMasterTab.SecOrFileLvl,'file') & contains(RelMasterTab.AN_Type,'All'),:);
Rel_HTAd_FileLvl = RelMasterTab(contains(RelMasterTab.SecOrFileLvl,'file') & contains(RelMasterTab.AN_Type,'ChildDir'),:);

RelSummTab_HTAd = GetRelSummaries(Rel_HTAd_FileLvl);
RelSummTab_HAllAd = GetRelSummaries(Rel_HAllAd_FileLvl);
writetable(RelSummTab_HTAd,'ReliabilityAggregateTab.xlsx','Sheet','H_TAd_FileLvl');
writetable(RelSummTab_HAllAd,'ReliabilityAggregateTab.xlsx','Sheet','H_AllAd_FileLvl');

%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%FUNCTIONS
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%This function gets summary table (RelSummTab) with mean and total error rates given the input table with file (or section) level error numbers.
function [RelSummTab] = GetRelSummaries(RelTab)

    %Means
    MeanFAR = mean(RelTab.NumFA./RelTab.NumSpeech_Hum,'omitnan');
    MeanMR = mean(RelTab.NumMiss./RelTab.NumSpeech_Hum,'omitnan');
    MeanCR = mean(RelTab.NumConf./RelTab.NumSpeech_Hum,'omitnan');
    MeanIER = mean((RelTab.NumFA + RelTab.NumMiss + RelTab.NumConf)./RelTab.NumSpeech_Hum,'omitnan');
    MeanPrcAg = mean(RelTab.PercentAgreement,'omitnan');
    MeanCK = mean(RelTab.CohensKappa,'omitnan');

    %Totals
    TotFAR = sum(RelTab.NumFA)/sum(RelTab.NumSpeech_Hum);
    TotMR = sum(RelTab.NumMiss)/sum(RelTab.NumSpeech_Hum);
    TotCR = sum(RelTab.NumConf)/sum(RelTab.NumSpeech_Hum);
    TotIER = sum(RelTab.NumFA + RelTab.NumMiss + RelTab.NumConf)/sum(RelTab.NumSpeech_Hum);

    %Get total percent agreement and Cohens Kappa. We need to compute this from the number of frame matches etc, cuz you cant just sum the file level percent agreements to get 
    % the total.
    TotNumFrames = sum(RelTab.NumFramesLENA_CHNSP + RelTab.NumFramesLENA_CHNNSP + RelTab.NumFramesLENA_AN + RelTab.NumFramesLENA_NA_NotLab);
    LENA_Probability = [sum(RelTab.NumFramesLENA_CHNSP) sum(RelTab.NumFramesLENA_CHNNSP)  sum(RelTab.NumFramesLENA_AN)  sum(RelTab.NumFramesLENA_NA_NotLab)]/TotNumFrames; 
    Hum_Probability = [sum(RelTab.NumFramesHum_CHNSP) sum(RelTab.NumFramesHum_CHNNSP)  sum(RelTab.NumFramesHum_AN)  sum(RelTab.NumFramesHum_NA_NotLab)]/TotNumFrames; 
    ExpectedAgreement = sum(LENA_Probability.*Hum_Probability); %This is the expected probability that human annotator and LENA agree on a label by chance (based on the 
    % observed probabilities for each label for LENA and human annotator)
    %Get he total number of all frames where LENA and Hum agree divided by total number of frames. This is the percent agreement
    ObsAgreement = sum([sum(RelTab.NumFrameMatch_CHNSP) sum(RelTab.NumFrameMatch_CHNNSP) sum(RelTab.NumFrameMatch_AN)  sum(RelTab.NumFrameMatch_NA_NotLab)]/TotNumFrames); 
    TotCK = (ObsAgreement-ExpectedAgreement)/(1-ExpectedAgreement);
    TotPrcAg = ObsAgreement;

    Vars = {'PrcAg','CK','FAR','MR','CR','IER'}'; %table var names
    MeanVals = [MeanPrcAg MeanCK MeanFAR MeanMR MeanCR MeanIER]';
    TotVals = [TotPrcAg TotCK TotFAR TotMR TotCR TotIER]';
    RelSummTab = table(Vars,MeanVals,TotVals);
end

%-----------------------------------------------------------------
%This function gets total (overall) confusion matrix as well as total precision and recall for key segments, given the relevant structure as input.
function [Tot_IntersectNums,TotPrec_KeySegs,TotRecall_KeySegs] = GetConfMatPrecAndRecallSummaries(CM_Struct)

    %Totals
    Tot_IntersectNums = sum(cat(3,CM_Struct.LabelSetIntersectNums_Cell{:}),3); %sum across all confusion matrices

    TotPrecDenom_Row = sum(cat(3,CM_Struct.NumDenom_Prec_RowVec_Cell{:}),3); %sum the precision denominator vectors (this is the denominator to divide by to compute precision)
    TotRecallDenom_Col = sum(cat(3,CM_Struct.NumDenom_Recall_ColVec_Cell{:}),3); %simiraly for recall denominator
    TotIntersectNumsDiagonal_Col = diag(Tot_IntersectNums); %get diagonal of conf matrix

    TotPrec_KeySegs = TotIntersectNumsDiagonal_Col(1:3)./TotPrecDenom_Row(1:3)'; %compute total precision for key segments (indices 1 throughj 3 of the diagonal of conf matrix)
    TotRecall_KeySegs = TotIntersectNumsDiagonal_Col(1:3)./TotRecallDenom_Col(1:3); %similarly for recall
end