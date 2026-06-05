%@author info; Feb 2025
%This set of functions generates supplementary figs that summarise the data: Bar plots and box charts for duration and voc nums by age and voc type 
%(for LENA day-long data) 
clear; clc
cd('~/BaseDataPath/Data/ResultsTabs/DataDescriptionSummaries') %go to relevant path

%set colours for different plots
LdayClrs_ChnAn = [0.14 0.36 0.59; %CHN
                  0.05 0.48 0.12]; %AN
LdayClrs_ChnspChnnsp = [0.70 0.83 0.96; %CHNSP
                        0.34 0.6 0.76]; %CHNNSP
LdayClrs_KeySegLabels = [0.70 0.83 0.96; %CHNSP
                        0.34 0.6 0.76;  %CHNNSP
                        0.05 0.48 0.12];      %AN

%read in LENA numbers table (totals by age and voc type)
NumTotsTab = readtable('TotVocNumsSummaries_0IviMerged_ChnAdOnly_Lday.xlsx','Sheet','TotNumByAgeAndVocType');                   
%read in LENA numbers data table (totals by file)
NumDataTab = readtable('TotVocNumsSummaries_0IviMerged_ChnAdOnly_Lday.xlsx','Sheet','FileLvlTotNumOfSegs');

%read in LENA numbers table (totals by age and voc type)
DurTotsTab = readtable('TotVocDurSummaries_0IviMerged_ChnAdOnly_Lday.xlsx','Sheet','TotDurByAgeAndVocType');
%read in LENA numbers data table (totals by file)
DurDataTab = readtable('TotVocDurSummaries_0IviMerged_ChnAdOnly_Lday.xlsx','Sheet','FileLvlTotDurOfSegs');

 %get data in plottable form
[NumTab_barplot,NumYvars_boxcht,NumClrGrp_boxcht,NumAges_x_boxcht] = GetLdayDataToPlt(NumTotsTab,NumDataTab,'Num');
[DurTab_barplot,DurYvars_boxcht,DurClrGrp_boxcht,DurAges_x_boxcht] = GetLdayDataToPlt(DurTotsTab,DurDataTab,'Dur');
                     


% Create figure: LENA bar plots (number of vocs)
figure1 = figure('PaperType','<custom>','PaperSize',[21.5 11],'Color',[1 1 1]);
axes1 = axes('Parent',figure1,'Position',[0.0628494835009205 0.121857707509881 0.378949458298021 0.815]); hold(axes1,'on');
GetLdayBarPlots(NumTab_barplot,LdayClrs_ChnAn,LdayClrs_ChnspChnnsp) %plot using function
legend({'Ch','Ad','ChSp','ChNsp'},'Position',[0.31944445680042 0.851778656126483 0.117063492063492 0.0744400527009222],'NumColumns',2)
ylim(axes1,[0 132000]); ylabel('Total number of vocalisations'); xlabel('Infant age (months)'); title('A');
hold(axes1,'off'); set(axes1,'FontSize',24,'XLimitMethod','tight','XTick',[3 6 9 18],'YLimitMethod','tight','ZLimitMethod','tight');

axes2 = axes('Parent',figure1,'Position',[0.611111111111111 0.121857707509881 0.387222790101975 0.815]); hold(axes2,'on');
GetLdayBoxCht(NumAges_x_boxcht,NumYvars_boxcht,NumClrGrp_boxcht,LdayClrs_KeySegLabels)
ylabel({'Total number of vocalisations';'(recording day-level)'}); xlabel('Infant age (months)'); title('B');
hold(axes2,'off'); set(axes2,'FontSize',24,'XTick',[3 6 9 18],'YGrid','on','YMinorGrid','on','YMinorTick','on','YTick',[0 1000 2000 3000 4000 5000]);
legend({'ChSp','ChNsp','Ad'},'Position',[0.921626966329562 0.816864295125165 0.0714285714285714 0.10935441370224]);



% Create figure: LENA bar plots (duration of vocs)
figure1 = figure('PaperType','<custom>','PaperSize',[21.5 11],'Color',[1 1 1]);
axes1 = axes('Parent',figure1,'Position',[0.0628494835009205 0.121857707509881 0.378949458298021 0.815]); hold(axes1,'on');
GetLdayBarPlots(DurTab_barplot,LdayClrs_ChnAn,LdayClrs_ChnspChnnsp) %plot using function
legend({'Ch','Ad','ChSp','ChNsp'},'Position',[0.31944445680042 0.851778656126483 0.117063492063492 0.0744400527009222],'NumColumns',2)
ylim(axes1,[0 240000]); ylabel('Total duration of vocalisations (s)'); xlabel('Infant age (months)'); title('A');
hold(axes1,'off'); set(axes1,'FontSize',24,'XLimitMethod','tight','XTick',[3 6 9 18],'YLimitMethod','tight','ZLimitMethod','tight');

axes2 = axes('Parent',figure1,'Position',[0.611111111111111 0.121857707509881 0.387222790101975 0.815]); hold(axes2,'on');
GetLdayBoxCht(DurAges_x_boxcht,DurYvars_boxcht,DurClrGrp_boxcht,LdayClrs_KeySegLabels)
ylabel({'Total vocalisation duration';'(seconds; recording day-level)'}); xlabel('Infant age (months)'); title('B');
hold(axes2,'off'); set(axes2,'FontSize',24,'XTick',[3 6 9 18],'YGrid','on','YMinorGrid','on','YMinorTick','on','YTick',[0 2000 4000 6000 8000 10000]);
legend({'ChSp','ChNsp','Ad'},'Position',[0.921626966329562 0.816864295125165 0.0714285714285714 0.10935441370224]);

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%FUNCTIONS USED
%-----------------------------------------------------------------------------------------------
%This function takes in tables with relevant data tables and outputs data in plottable form
% Inputs: -TotsTab_AgeVocType: totals (duration or numbers) of vocs by age and voctype 
%         -TotsTab_FileLvl: similar totals for CHNSP, CHNNSP, CHN, AN (and total of all key segments) at the file level
%         -NumOrDur: string specifying whether we are looking at total durations or total numbers of vocs
% 
% Outputs: -Tab_barplot: table with data for bar plot. Contains totals for CHNSP, CHNNSP, and AN (in that order) for each age
%          -Yvars_boxcht, ClrGrp_boxcht,Ages_x_boxcht: data for boxchart. Yvars is the actual series of voc totals or total durations for each day-long 
%                  recording. This goes into computing the details for the boxchart. ClrGrp and Ages_x are vectors of the same size as Yvars that are used
%                  to determine group the data by colour (speaker label, in this case), and into groups along the x axis (age, in this case).
function [Tab_barplot,Yvars_boxcht,ClrGrp_boxcht,Ages_x_boxcht] = GetLdayDataToPlt(TotsTab_AgeVocType,TotsTab_FileLvl,NumOrDur)

    %generate table for plotting (in order of CHNSP, CHNNSP, AN)
    Tab_barplot = [TotsTab_AgeVocType(contains(TotsTab_AgeVocType.SpkrLvlLabels,'CHNSP'),:).Totals...
                TotsTab_AgeVocType(contains(TotsTab_AgeVocType.SpkrLvlLabels,'CHNNSP'),:).Totals ...
                TotsTab_AgeVocType(contains(TotsTab_AgeVocType.SpkrLvlLabels,'AN'),:).Totals]; 
    %The above creates an array with [(column vector of CHNSP totals for each age)  (column vector of CHNNSP totals for each age)  (column vector of AN totals for each age)] .
    
    if ~isequal(sort(unique(TotsTab_FileLvl.InfantAgeMonth)),[3 6 9 18]') %checks!
        error('Ages other than 3, 6, 9, or 18 months present. Need to adapt code')
    end

    ReqVarNames = strcat(NumOrDur,'_',{'CHNSP','CHNNSP','AN'}); %get set of required variable names
    Yvars_boxcht = []; ClrGrp_boxcht = []; Ages_x_boxcht = []; %initialise matrices to store things for boxchart plotting
    for i = 1:numel(ReqVarNames) %go through list of var names
        Yvars_boxcht = [Yvars_boxcht; TotsTab_FileLvl.(ReqVarNames{i})]; %populate the data for the y coords for boxchart; this is a column vector
        ClrGrp_boxcht = [ClrGrp_boxcht; i*ones(size(TotsTab_FileLvl.(ReqVarNames{i})))];  % similarly for the data to separate the boxcharts by colour; each unique colour group is indexed by i
        Ages_x_boxcht = [Ages_x_boxcht; TotsTab_FileLvl.InfantAgeMonth]; %simiarly for the x coords (ages)
    end
end

%-----------------------------------------------------------------------------------------------
%This function takes in tables with data in plottable form and outputs bar plots showing total numbers or duration of key segs by age.
% Inputs: -Ytab: totals (duration or numbers) of vocs by age and voctype. Each row is an age and each columns is the totals for a given speaker label.
%               So, the first column would be for CHNSP, with the first element in the first row giving total CHNSP (num or duration) at 3 mo, first elemnt
%               in second row would be the same at 6 mo, etc. Similarly, second column is CHNNSP, and so on. 
%         -LdayClrs_ChnAn,LdayClrs_ChnspChnnsp: Colours for An and Chn; and for Chnsp and Chnnsp.
function [] = GetLdayBarPlots(Ytab,LdayClrs_ChnAn,LdayClrs_ChnspChnnsp)

   Y_ChnAn = [Ytab(:,1)+Ytab(:,2) Ytab(:,3)]; %get data to plot for Chn (Chnsp + Chnnsp) and An. These form grouped bars
   Y_ChnspChnnsp = [Ytab(:,1) Ytab(:,2)]; %get data for Chnsp and Chnnsp. These are grouped as smaller bars within the Chnsp bar from above

   bp1 = bar([3 6 9 18], Y_ChnAn,'BarWidth',1,'EdgeColor','k','LineWidth',0.5); %plot Chn and An bars
   bp1(1).FaceColor = LdayClrs_ChnAn(1,:); %set colours
   bp1(2).FaceColor = LdayClrs_ChnAn(2,:);

   bp2 = bar(bp1(1).XEndPoints, Y_ChnspChnnsp,'EdgeColor', 'k', 'BarWidth',1,'GroupWidth',0.25,'LineWidth',0.5); %plot teh Chnsp and Chnnsp bars
   bp2(1).FaceColor = LdayClrs_ChnspChnnsp(1,:);
   bp2(2).FaceColor = LdayClrs_ChnspChnnsp(2,:);
end

%-----------------------------------------------------------------------------------------------
%This function takes in tables with data in plottable form and outputs box charts for total number or duration of key segments (at the rec day level), grouped by age.
% Inputs: -Ages_x,Yvars,ColourGroup: vectors with age, totals at rec day level (duration or numbers), and a proxy number id'ing whether data is for 
%          CHNSP, CHNNSP, or AN. Goes into box plot. 
%         -LdayClrs_KeySegLabels: Colours for key segments, in order of Chnsp, CHNNSP, and AN
function [] = GetLdayBoxCht(Ages_x,Yvars,ColourGroup,LdayClrs_KeySegLabels)

    b1 = boxchart(Ages_x,Yvars,'GroupByColor',ColourGroup,'MarkerStyle','.','MarkerSize',15,...
        'BoxMedianLineColor','k','LineWidth',1.5,'BoxWidth',0.8,'BoxFaceAlpha',1,'Notch','on'); %plot box charts
    for i = 1:numel({'CHNSP','CHNNSP','AN'}) %set rest of box charat properties
        b1(i).BoxFaceColor = LdayClrs_KeySegLabels(i,:);
        b1(i).WhiskerLineColor = 'k';%ReqClrs(i,:);
        %b1(i).BoxMedianLineColor = 'k';%ReqClrs(i,:);
        b1(i).MarkerColor = LdayClrs_KeySegLabels(i,:);
        b1(i).BoxEdgeColor = 'k';%ReqClrs(i,:);
    end
    b1(3).BoxFaceAlpha = 0.5; %set alpha for adult bar lower
end