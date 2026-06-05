clear; clc

% @authorinfo; Feb 2026
% This script is designed to show the burstiness in the data across different time scales a la figures in Abney et al. 2015 (Multiple Coordination Patterns in Infant 
% and Adult Vocalizations) and Warlaumont et al, 2021 (Daylong Mobile Audio Recordings Reveal Multitimescale Dynamics in Infants' Vocal Productions and Auditory 
% Experiences).
% Specifically, to show this consistenly for LENA daylong and human listener labelled datasets, the following steps are taken:
    % - Randomly choose a human listener labelled file.
    % - Check for whether it has a corresponding LENA daylong file that does not have recorder pauses (because with recorder pauses, plotting onsets of vocalisations 
        % for vocs in different subrecs will result in IEIs that are not actually present in the data being represented (i.e., those from the end of one subrec to 
        % the start of the next)
    % - Randomly choose a 5 minute section from the human labelled dataset
    % - Pick an hour-long window that contains that 5 minute window
    % - Plot the daylong infant (ChSp) and adult onsets + the hour subset (from daylong data) + the 5 min (daylong, human labelled).

%------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLEASE CHANGE PATHS AND STRINGS IN FUNCTION CALL APPROPRIATELY
Basepath = '~/Basepath/';
%LENA daylong data
Lday_Path = strcat(Basepath,'LENAData/A8_NoAcoustics_0IviMerged_LENA/'); %path
Lday_FileStr = '*_NoAcoustics_0IviMerged_LENA.csv'; %common string added to the file name root
%Human labelled data path: all adult vocs
H_All_Path = strcat(Basepath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A9_NoAcoustics_0IviMerged_Hum/');
H_All_FileStr = '*_NoAcoustics_0IviMerged_Hum.csv';
%Human labelled data path: child directed adult only
H_TAd_Path = strcat(Basepath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A11_NoAcoustics_0IviMerged_Hum_ChildDirANOnly/');
H_TAd_FileStr = '*_NoAcoustics_0IviMerged_ChildDirANOnly_Hum.csv';

AnnotSpreadSheet = readtable(strcat(Basepath,'MetadataFiles/FNSTETSimplified.csv')); %annotation spreadsheet that has details of annotated 5 min sections
%------------------------------------------------------------------------------------------------------------------------------------------------------------------------

%--1. Randomly choose human labelled file and verify that corresponding Lday data has no subrecs-------------------------------------
cd(H_All_Path);
H_All_Files = dir(H_All_FileStr); %get human labelled files
Num_HAll_Files = numel(H_All_Files); %get number of files

%We want two things to be true: 
    % (a) the LENA daylong data should not have any subrecs
    % (b) we should be able to get a 1 hour window that contains the chosen 5 minute section
% The two while conditions below allow for that.
while true %condition to pick a human labelled file all of whose sections easily allow for a 1 hour window that contains the chosen 5 minute section
    while true %condition to pick a daylong file that has no subrecs
        H_All_FileId = randi([1 Num_HAll_Files],1); %randomly choose file
        H_All_FnRoot = erase(H_All_Files(H_All_FileId).name,erase(H_All_FileStr,'*')); %get the file name root for the selected file
        Corresp_Lday_Tab = readtable(strcat(Lday_Path,H_All_FnRoot,erase(Lday_FileStr,'*'))); %get corresponding LENA daylong file
        %unique(Corresp_LdayTab.SectionNum) %try till we get to a daylong file that has no subrecs
        if numel(unique(Corresp_Lday_Tab.SectionNum)) == 1
            break
        end
    end
    
    LastTimeInDay = Corresp_Lday_Tab.start(end); %get the last time in the day 
    
%--2. read in the human labelled tabs (all adult vocs and only child directed adult voics)-------------------------------------
    H_All_Tab = readtable(H_All_Files(H_All_FileId).name); %read in the human listener labelled tab (all adult vocs)
    Corresp_H_TAd_Tab = readtable(strcat(H_TAd_Path,H_All_FnRoot,erase(H_TAd_FileStr,'*')));%(child directed adult vocs only)
    
    AnnotSubTab = AnnotSpreadSheet(contains(AnnotSpreadSheet.FileName,H_All_FnRoot),:); %id the file and section in the annotation spreadsheet
    if all((AnnotSubTab.StartTimeSS - (30*60)) > 0) && all((AnnotSubTab.EndTimeSS + (30*60)) < LastTimeInDay) &&... %30 minutes on eah side
        all((AnnotSubTab.EndTimeSS - AnnotSubTab.StartTimeSS) == 300) %all sections should be 5 minutes
        break
    end
end

%randomly pick a 5 min section
H_All_Secs = unique(H_All_Tab.SectionNum); %get vector of unique section nums
Rand_HAll_Sec_ind = randi([1 numel(H_All_Secs)],1); %pick one at random by index
Rand_HAll_Sec = H_All_Secs(Rand_HAll_Sec_ind); %actually pick the section number using the randomly selected index

%Error check
if numel(unique(Corresp_H_TAd_Tab.SectionNum)) ~= numel(H_All_Secs)
    error('The all adult and child directed adult only tables have different number of 5 min sections')
end

%subset the all adult vocs and only child directed adult vocs files for the chosen section.
H_All_SubTab = H_All_Tab(H_All_Tab.SectionNum == Rand_HAll_Sec,:); %all adult
Corresp_H_TAd_SubTab = Corresp_H_TAd_Tab(Corresp_H_TAd_Tab.SectionNum == Rand_HAll_Sec,:); %child directed adult only


%--3. Identify the annotation spreadsheet section that corresponds to the chosen section (to get section boundaries.-------------------------------------
for i = 1:height(AnnotSubTab)
    AnnotSt = AnnotSubTab.StartTimeSS(i); AnnotEnd = AnnotSubTab.EndTimeSS(i); %get section boundaries per spreadsheet
    if (H_All_SubTab.xEnd(1) >= AnnotSt - 1) && (Corresp_H_TAd_SubTab.xEnd(1) >= AnnotSt - 1)...
            && (H_All_SubTab.start(end) <= AnnotEnd + 1) && (Corresp_H_TAd_SubTab.start(end) <= AnnotEnd + 1) %additional one second buffer just in case the actual 
        %tagged voc boundaries are just a bit beyond the spreadsheet boundaries
        AnnotatedSecId_Spreadsheet = i; %get the id of the section wrt to the annotation spreadsheet's subsetted table
        break
    end
end

%Error check!
if ~exist("AnnotatedSecId_Spreadsheet")
    error(['The AnnotatedSecId_Spreadsheet variable does not exist. This means that either the section does not match any of the \n ' ...
        'annotation boundaries OR that the same section number identifies different sections for the *All adult vocs* and \n' ...
        '*child directed adult vods ONLY* datasets.'])
end

% %UNCOMMENT AS NEEDED: This is just to see if everything is in order and just print this stuf to console. .
% AnnotSubTab(AnnotatedSecId_Spreadsheet,:)
% H_All_SubTab([1 end],:)
% Corresp_H_TAd_SubTab([1 end],:)

HrStart = AnnotSt - 25*60; %pick hour start 25 minutes before the start of the 5 min section
HrEnd = AnnotEnd + 30*60; %pick hour end 30 minutes from the end of the 5 min section

%Get Lena daylong data's hour and 5 min data.
CorrespLday_HrTab = Corresp_Lday_Tab(Corresp_Lday_Tab.start >= HrStart & Corresp_Lday_Tab.xEnd <= HrEnd,:);
CorrespLday_5minTab = Corresp_Lday_Tab(Corresp_Lday_Tab.start >= AnnotSt & Corresp_Lday_Tab.xEnd <= AnnotEnd,:);

%--4. Computing burstiness to report------------------------------------------------------------------------------------------------------------
SpkrTypesForTab = {'CHNSP','AN'};
DataTypesForTab = {'Lday','Lday_Hr','Lday_5min','H_All_5minSec','H_TAd_5minSec'}';
CorrespDataTabs_ForBurstiness = {Corresp_Lday_Tab,CorrespLday_HrTab,CorrespLday_5minTab,H_All_SubTab,Corresp_H_TAd_SubTab}; %put the correspodning tabs into a cell
for i = 1:numel(DataTypesForTab)
    for j = 1:numel(SpkrTypesForTab)
        BurstinessVal(i,j) = GetBurstinessVal(CorrespDataTabs_ForBurstiness{i},SpkrTypesForTab{j}); %compute burstiness
    end
end
BurstinessTab = array2table(BurstinessVal); %turn to table
BurstinessTab = [table(DataTypesForTab) BurstinessTab]; %plop data type col
BurstinessTab.Properties.VariableNames = ['DataType',SpkrTypesForTab];
BurstinessTab
disp(['File name root is ' H_All_FnRoot '; 5 min section is section number ' Rand_HAll_Sec])


%% Plotting
figure1 = figure('PaperType','<custom>','PaperSize',[20 6.5],'WindowState','maximized','Color',[1 1 1]);

%plotting inputs
ylim_Min = 0; ylim_Max = 2; %to set the scale of plots
LdayClr = [0.3 0.3 0.3];
H_All_Clr = [63 139 156]/256; H_TAd_Clr = [163 179 96]/256;


%--ChSp vocs: daylong
axes1 = axes('Parent',figure1,'Position',[0.0363756613756614 0.573126092020967 0.444156445406442 0.153359056493885]); hold(axes1,'on'); %daylong
patch([HrStart HrStart HrEnd HrEnd ], ...
      [ylim_Min ylim_Max ylim_Max ylim_Min],[0.6 0.6 0.6],'FaceAlpha',0.2,'EdgeColor','none'); %1 hour patch
PlotOnsets(Corresp_Lday_Tab,'CHNSP',1,LdayClr) %user defined fn; see below; last two inputs are Yval,Clr
axis(axes1,'tight'); box(axes1,'on'); 
title({'Infant (ChSp)'});
ylim(axes1,[ylim_Min ylim_Max]);
hold(axes1,'off');
set(axes1,'FontName','Helvetica Neue','FontSize',24,'XTick',zeros(1,0),'YTick',zeros(1,0));


%--ChSp vocs: hour
axes2 = axes('Parent',figure1,'Position',[0.0363756613756619 0.409632352941176 0.444156445406442 0.153359056493885]); hold(axes2,'on'); 
patch([AnnotSt AnnotSt AnnotEnd AnnotEnd], ...
      [ylim_Min ylim_Max ylim_Max ylim_Min],[0.6 0.6 0.6],'FaceAlpha',0.2,'EdgeColor','none');
PlotOnsets(CorrespLday_HrTab,'CHNSP',1,LdayClr)
xlim(axes2,[HrStart HrEnd]); ylim(axes2,[ylim_Min ylim_Max]); 
box(axes2,'on'); hold(axes2, 'off');
set(axes2,'XTick',zeros(1,0),'YTick',zeros(1,0));


%--ChSp vocs: 5 min
axes3 = axes('Parent',figure1,'Position',[0.0363756613756619 0.24490099009901 0.444156445406442 0.153359056493885]); hold(axes3,'on'); 
%NaN plotting for legend
plot(NaN,NaN,'|','LineWidth',6,'Color',LdayClr,'MarkerSize',4)
plot(NaN,NaN,'|','LineWidth',6,'Color',H_All_Clr,'MarkerSize',4)
plot(NaN,NaN,'|','LineWidth',6,'Color',H_TAd_Clr,'MarkerSize',4)
%Actual plotting
PlotOnsets(CorrespLday_5minTab,'CHNSP',1,LdayClr) %Yvals are 1, 0.75, and 0.5, for these 3 plottings
PlotOnsets(H_All_SubTab,'CHNSP',0.75,H_All_Clr)
PlotOnsets(Corresp_H_TAd_SubTab,'CHNSP',0.5,H_TAd_Clr)
legend({'L (day)', 'H (5min; All Ad)', 'H (5min; T-Ad)'},'FontSize',24,'Orientation','horizontal')
xlim(axes3,[AnnotSt AnnotEnd]); ylim(axes3,[ylim_Min ylim_Max]); 
box(axes3,'on');hold(axes3, 'off');
set(axes3,'XLimitMethod','tight','XTick',zeros(1,0),'YLimitMethod','tight','YTick',zeros(1,0),'ZLimitMethod','tight');



%--AD vocs: daylong
axes4 = axes('Parent',figure1,'Position',[0.522721861471858 0.574363715783343 0.44415644540644 0.153359056493885]); hold(axes4,'on'); %daylong
patch([HrStart HrStart HrEnd HrEnd ], ...
      [ylim_Min ylim_Max ylim_Max ylim_Min],[0.6 0.6 0.6],'FaceAlpha',0.2,'EdgeColor','none');
PlotOnsets(Corresp_Lday_Tab,'AN',1, LdayClr)
axis(axes4,'tight'); box(axes4,'on'); 
title({'Adult (Ad)'});
ylim(axes4,[ylim_Min ylim_Max]); 
set(axes4,'FontName','Helvetica Neue','FontSize',24,'XTick',zeros(1,0),'YTick',zeros(1,0)); 
hold(axes4, 'off');


%--AD vocs: hour
axes5 = axes('Parent',figure1,'Position',[0.522721861471859 0.409632352941176 0.44415644540644 0.153359056493885]); hold(axes5,'on'); %hour
patch([AnnotSt AnnotSt AnnotEnd AnnotEnd], ...
      [ylim_Min ylim_Max ylim_Max ylim_Min],[0.6 0.6 0.6],'FaceAlpha',0.2,'EdgeColor','none');
PlotOnsets(CorrespLday_HrTab,'AN',1, LdayClr)
xlim(axes5,[HrStart HrEnd]); ylim(axes5,[ylim_Min ylim_Max]);
box(axes5,'on'); hold(axes5, 'off');
set(axes5,'XTick',zeros(1,0),'YTick',zeros(1,0));


%--AD vocs: 5 min
axes6 = axes('Parent',figure1,'Position',[0.522721861471858 0.24490099009901 0.44415644540644 0.153359056493885]); hold(axes6,'on'); %5-minute
CorrespLday_5minTab = Corresp_Lday_Tab(Corresp_Lday_Tab.start >= AnnotSt & Corresp_Lday_Tab.xEnd <= AnnotEnd,:);
PlotOnsets(CorrespLday_5minTab,'AN',1, LdayClr)
PlotOnsets(H_All_SubTab,'AN',0.75,H_All_Clr)
PlotOnsets(Corresp_H_TAd_SubTab,'AN',0.5,H_TAd_Clr)
xlim(axes6,[AnnotSt AnnotEnd]); ylim(axes6,[ylim_Min ylim_Max]); 
box(axes6,'on'); hold(axes6,'off');
set(axes6,'XLimitMethod','tight','XTick',zeros(1,0),'YLimitMethod','tight','YTick',zeros(1,0),'ZLimitMethod','tight');


%Annotations
annotation(figure1,'line',[0.501984126984125 0.501984126984125],[0.992811881188119 0.20420792079208],'Color',[0.8 0.8 0.8],'LineWidth',2,'LineStyle',':');
annotation(figure1,'textbox',[0.037037037037037 0.518564356435644 0.0608465608465608 0.0445544554455446],'String',{'1 hour'},'FontSize',22,'EdgeColor','none');
annotation(figure1,'textbox',[0.0376984126984127 0.680693069306931 0.138558201058201 0.0445544554455446],'String',{'Daylong recording'},'FontSize',22,...
    'EdgeColor','none');
annotation(figure1,'textbox',[0.0370370370370347 0.353960396039604 0.0830026455026455 0.0445544554455445],'String',{'5 minutes'},'FontSize',22,'EdgeColor','none');


%A, B, C, D, etc
annotation(figure1,'textbox',[0.0132275132275132 0.720297029702971 0.0185185185185185 0.0445544554455446],'String','A','FontWeight','bold',...
    'FontSize',26.4,'FitBoxToText','off','EdgeColor','none');
annotation(figure1,'textbox',[0.0138888888888889 0.556930693069307 0.0185185185185185 0.0445544554455446],'String','B','FontWeight','bold',...
    'FontSize',26.4,'FitBoxToText','off','EdgeColor','none');
annotation(figure1,'textbox',[0.0132275132275132 0.391089108910891 0.0185185185185185 0.0445544554455446],'String','C','FontWeight','bold',...
    'FontSize',26.4,'FitBoxToText','off','EdgeColor','none');
annotation(figure1,'textbox',[0.970238095238089 0.392326732673268 0.0185185185185185 0.0445544554455446],'String','F','FontWeight','bold',...
   'FontSize',26.4,'FitBoxToText','off','EdgeColor','none');
annotation(figure1,'textbox',[0.970238095238089 0.558168316831683 0.0185185185185185 0.0445544554455446],'String','E','FontWeight','bold',...
    'FontSize',26.4,'FitBoxToText','off','EdgeColor','none');
annotation(figure1,'textbox',[0.970238095238089 0.721534653465347 0.0185185185185185 0.0445544554455446],'String','D','FontWeight','bold',...
    'FontSize',26.4,'FitBoxToText','off','EdgeColor','none');


%------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%Functions used
%------------------------------------------------------------
%This function plots the onsets of the specificed speaker type (Spkr) from the input table (IpTab). Yval is the Y-axis level, so if Yval = 1, then all the onsets are
% plotted as markers at y = 1, and onsets are indicated along the X axis. Clr specifies the colour for the plot markers.
function PlotOnsets(IpTab,Spkr,Yval,Clr)
    SpkrSubTab = IpTab(contains(IpTab.speaker,Spkr),:); %subset table
    plot(SpkrSubTab.start,Yval*ones(size(SpkrSubTab.start)),'|','LineWidth',2,'Color',Clr,'MarkerSize',8) %plot
end


%------------------------------------------------------------
%This function computes the burstiness quantity for the input table, for the given speaker type.
function BurstinessQt = GetBurstinessVal(IpTab,Spkr)

    if numel(unique(IpTab.SectionNum)) ~= 1
        error('There should only be one section number')
    end

    SpkrTab = IpTab(contains(IpTab.speaker,Spkr),:); %subset table

    CurrIeis = SpkrTab.start(2:end) - SpkrTab.xEnd(1:end-1); %get IEIs

    %Negatiev IEI error check.
    if ~all(CurrIeis >= 0)
        error('There are negative IEIs!')
    end

    %Check if there are NaN IEIs
    if numel(CurrIeis) ~= numel(CurrIeis(~isnan(CurrIeis)))
        warning('There are some NaN IEIs')
    end

    %calculate burstiness measure
    if numel(CurrIeis) >= 10 %only if there are at least 10 IEIs total at the recording day/validation data file-level
        BurstinessNum = (std(CurrIeis,'omitnan') - mean(CurrIeis,'omitnan'));
        BurstinessDenom = (std(CurrIeis,'omitnan') + mean(CurrIeis,'omitnan'));
        BurstinessQt = BurstinessNum/BurstinessDenom;

        if (BurstinessQt == -1) || (isnan(BurstinessQt))
            disp('Burstiness measure is -1 or NaN, this should not happen. Check the number of IEIs and what those IEIs look like.')
        end
    else
        BurstinessQt = NaN; %if there are fewer than 10 IEIs
    end 
end







