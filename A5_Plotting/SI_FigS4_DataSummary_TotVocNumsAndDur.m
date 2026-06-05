%@author info; Oct 2024
%This set of functions generates supplementary figs that summarise the data: Total number of vocalisations across the different datasets and total duration of vocs across 
% different datasets

clear; clc
cd('~/BaseDataPath/Data/ResultsTabs/DataDescriptionSummaries') %go to relevant path

BarClrs = [244 223 165; 119 39 89; 63 139 156]/256; %line colours for each data type
DatasetType = {'Lday';'L5min';'H5min-AllAd'}; %list of the data sets 

figure1 = figure('PaperType','<custom>','PaperSize',[15.5 12],'Color',[1 1 1]); %initialise figure

%subplot: tot voc nums
axes1 = subplot(1,2,1,'Parent',figure1); hold(axes1,'on');

for i = 1:numel(DatasetType) %go through the list of dataset types
    CurrTab = readtable(strcat('TotVocNumsSummaries_0IviMerged_ChnAdOnly_',DatasetType{i},'.xlsx'),'Sheet',1); %read the first sheet (total numbers)
    
    if height(CurrTab) > 1 %error check that the correct sheet is read in
        error('Table should only have 1 row since this has the overall totals')
    end

    b = bar(DatasetType(i),CurrTab.Num_Tot,'FaceColor',BarClrs(i,:),'EdgeColor','none','Horizontal','off'); %make bar plot
    set(b,'Labels',string(b.YData),'FontSize',20) %set labels for each bar
    
    % if strcmp(DatasetType{i},'H5min-AllAd') %add detail about T adult utterances for human listener labelled data
    %     CurrTabByVocType = readtable(strcat('TotVocNumsSummaries_0IviMerged_ChnAdOnly_',DatasetType{i},'.xlsx'),'Sheet',4); %read in sheet with totals by voc type
    % 
    %     if sum(contains(CurrTabByVocType.Properties.VariableNames,'Age')) > 0 %error check; note that the other possibilty is that we read in the overall totals but that is averted
    %         %because we clearly are reading in a different sheet number than the one for overall totals
    %         error('Table should not have a column name with the string Age in it, since this table only deals with voc type totals')
    %     end
    % 
    %     % NumT = CurrTabByVocType.Totals(contains(CurrTabByVocType.H_Annots,'T')); %get total number of T vocs
    %     % Tot_wo_T = CurrTab.Num_Tot - NumT; %get totals without T type
    %     % BarVal = [Tot_wo_T NumT]; %set vector for bar values
    %     % bar(DatasetType(i),BarVal,'stacked','FaceColor',BarClrs(i,:),'EdgeColor','w'); %make additioonal bar plot with white line separating total voc num without T and 
    %     % %total T type number
    % end
end

ylabel('Total number of vocalizations'); title('A');
axis(axes1,'tight'); hold(axes1,'off');
set(axes1,'FontSize',24,'XTickLabel',{'L (day)','L (5min)','H (5min)'}); % Set the remaining axes properties

%subplot: total durations
subplot1 = subplot(1,2,2,'Parent',figure1); hold(subplot1,'on');
for i = 1:numel(DatasetType) %go through the list of dataset types
    CurrTab = readtable(strcat('TotVocDurSummaries_0IviMerged_ChnAdOnly_',DatasetType{i},'.xlsx'),'Sheet',1); %Read the first sheet (total numbers)
    
    if height(CurrTab) > 1 %error check that the correct sheet is read in
        error('Table should only have 1 row since this has the overall totals')
    end

    b = bar(DatasetType(i),CurrTab.Dur_Tot,'FaceColor',BarClrs(i,:),'EdgeColor','none'); %make bar plot
    set(b,'Labels',string(b.YData),'FontSize',20) %set labels for each bar
end
ylabel('Total duration of vocalizations (s)'); title('B');
axis(subplot1,'tight'); hold(subplot1,'off');
set(subplot1,'FontSize',24,'XTickLabel',{'L (day)','L (5min)','H (5min)'}); % Set the remaining axes properties