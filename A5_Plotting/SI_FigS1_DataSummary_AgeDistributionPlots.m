%@author info; Oct 2024
%This set of functions generates supplementary figs that summarise the data: Distribution of ages (in days) for each infant age in month, for LENA day-long data and validation data.

clear; clc

cd('/~/BaseDataPath/Data/MetadataFiles') %go to relevant path for LENA day-long metadata
LdayMetadata = readtable('MergedTSAcousticsMetadata.csv'); %read in relevant table (LENA day long data)
ValMetadata = readtable('ValDataMergedTSMetaDataTab.csv'); %read in relevant table (validation data)
uAgeMonth = [3 6 9 18]; %get set of unique ages in months used in the study

%Set Colours to plot
ClrsForAgeMnth =  [0.988235294117647 0.733333333333333 0.631372549019608;
                   0.984313725490196 0.415686274509804 0.290196078431373;
                   0.796078431372549 0.0941176470588235 0.113725490196078;
                   0.403921568627451 0 0.0509803921568627]; %set face colours for each age
ClrForExcludedAgeDays = [0.63921568627451 0.635294117647059 0.635294117647059]; %grey for excluded ages because they are not 3, 6, 9, or 18 mos

%get data to plot
[Lday_uAgeDays_Month_i,Lday_NumAgeDays_Months_i,Lday_uAgeDaysExcludedMos,Lday_Num_uAgeDaysExcludedMos] = GetAgeDistDataToPlot(uAgeMonth,LdayMetadata);
[Val_uAgeDays_Month_i,Val_NumAgeDays_Months_i,Val_uAgeDaysExcludedMos,Val_Num_uAgeDaysExcludedMos] = GetAgeDistDataToPlot(uAgeMonth,ValMetadata);
if ~isempty(Val_uAgeDaysExcludedMos) %error check
    error('There should not be any excluded months in validation data')
end

%PLOTTING%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
figure1 = figure('PaperType','<custom>','PaperSize',[21.5 11.5],'WindowState','maximized','Color',[1 1 1]);


%LENA DAY-LONG DATA
axes1 = axes('Parent',figure1,'Position',[0.0813492063492062 0.566997518610422 0.906746031746032 0.413151364764268]); hold(axes1,'on');

for i = 1:numel(uAgeMonth) %plot bars for each age
    bar(Lday_uAgeDays_Month_i{i},Lday_NumAgeDays_Months_i{i}','FaceColor',ClrsForAgeMnth(i,:),'EdgeColor','none','BarWidth',0.7)
end

title('A'); ylabel({'Number of',' day-long recordings'});
xlim(axes1,[80 566.4]); ylim(axes1,[0 10]); hold(axes1,'off');
set(axes1,'FontName','Helvetica Neue','FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorGrid','on','XMinorTick','on','XTick',...
    [80 120 160 200 240 280 320 360 400 440 480 520 560],'XTickLabel',{'','','','','','','','','','','','',''},...
    'YGrid','on','YLimitMethod','tight');
legend({'3 months','6 months','9 months','18 months'},'Position',[0.794146870909473 0.893300248138958 0.181878306878307 0.0700992555831266],'NumColumns',2);


%VALIDATION DATA
axes2 = axes('Parent',figure1,'Position',[0.0813492063492058 0.107518610421836 0.906746031746032 0.413151364764268]); hold(axes2,'on');
for i = 1:numel(uAgeMonth) %plot bars for each age
    bar(Val_uAgeDays_Month_i{i},Val_NumAgeDays_Months_i{i}','FaceColor',ClrsForAgeMnth(i,:),'EdgeColor','none','BarWidth',0.7)
end
title('B'); ylabel({'Number of','files (validation data)'}); xlabel('Infant age (days)');
xlim(axes2,[80 566.4]); ylim(axes2,[0 10]); hold(axes2,'off');
set(axes2,'FontName','Helvetica Neue','FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorGrid','on','XMinorTick','on','XTick',...
    [80 120 160 200 240 280 320 360 400 440 480 520 560],'XTickLabel',{'80','120','160','200','240','280','320','360','400','440','480','520','560'},...
    'YGrid','on','YLimitMethod','tight');


%-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%FUNCTIONS USED
%-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function [uAgeDays_Month_i,NumAgeDays_Months_i,uAgeDaysExcludedMos,Num_uAgeDaysExcludedMos] = GetAgeDistDataToPlot(uAgeMonth,MetadataTab)
%This function gets the data for the bar plots. Takes in the vector of unique ages (in months) and relevant metadata, and outputs the number of recordings at each unique age (in days) 
% for each relevant month as well as the number of recordings for each excluded age
% 
% Inputs: Vector of unique ages in months (uAgeMonth); relevant metadata (MetadataTab)
% 
% Outputs: - uAgeDays_Month_i: cell array of unique ages in days, with ith element of cell arrya corresponding to the subset of ages for the ith month
%          - NumAgeDays_Months_i: cell array with number of recordings for each unique age in days, with ith element of cell arrya corresponding to the subset of ages for the ith month
%          - uAgeDaysExcludedMos,Num_uAgeDaysExcludedMos: Similarly, vector of unqiue ages (in days) for exluded ages because they aren't part of the [3, 6, 9, 18] month ages,
%                                and the corresponding number of recordings.

    for i = 1:numel(uAgeMonth) %go through unique ages in months
        AgeMonthSubset = MetadataTab.InfantAgeDays(MetadataTab.InfantAgeMonth == uAgeMonth(i)); %get all infant ages in days corresponding to the ith age in months
        uAgeDays_Month_i{i} = unique(AgeMonthSubset); %store in cell array
        for j = 1:numel(uAgeDays_Month_i{i}) %go through list of unique ages in days for ith month
            Num_uAgeDays(j,1) = numel(AgeMonthSubset(AgeMonthSubset == uAgeDays_Month_i{i}(j))); %get number of files at each age (in days)
        end
        NumAgeDays_Months_i{i} = Num_uAgeDays; %store this in cell array where ith element is for the ith month
        clear Num_uAgeDays
    end
    
    %Now, do the same for all unique ages in days for ages that are not 3, 6, 9, or 18 mos.
    uAgeDaysExcludedMos = unique(MetadataTab.InfantAgeDays(~ismember(MetadataTab.InfantAgeMonth,uAgeMonth))); %get unique ages in days that do not belong to mos 3, 6, 9, or 18
    if ~isempty(uAgeDaysExcludedMos) %check if not empty (applicable for LENA daylong data)
        for j = 1:numel(uAgeDaysExcludedMos) %go through list of unique ages in days 
            Num_uAgeDaysExcludedMos(j,1) = numel(uAgeDaysExcludedMos(uAgeDaysExcludedMos == uAgeDaysExcludedMos(i))); %get number of files at each age (in days)
        end
    else %if empty, assign empty vector to output for the numbers vector (applicable to validation data)
        Num_uAgeDaysExcludedMos = [];
    end
end




















