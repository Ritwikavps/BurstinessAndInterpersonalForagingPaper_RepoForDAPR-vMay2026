%@author info; Feb 2025
%This set of functions generates supplementary figs that summarise the data: Bar plots and box charts for duration and voc nums by age and voc type 
% (for validation data) 

clear; clc
%go to relevant path
cd('~/BaseDataPath/Data/ResultsTabs/DataDescriptionSummaries') 

%set colours for different plots
ValdataClrs = [0.46 0.15 0.35; 
               0.25 0.54 0.61];  %the first is L5 data and the second is H5 data
H5AnnotClrs = [1 0.6 0.16; %C
               1 0.89 0.57; %X
               0.99 0.77 0.75; %R
               0.87 0.2 0.59; %L
               0.59 0.59 ,0.59; %T
               1 1 1;          %U
               0.33 0.15 0.56];     %N

%read in tables: L5
NumTotsTab_L5 = readtable('TotVocNumsSummaries_0IviMerged_ChnAdOnly_L5min.xlsx','Sheet','TotNumByVocType'); %numbers data table (totals by voc type)
NumDataTab_L5 = readtable('TotVocNumsSummaries_0IviMerged_ChnAdOnly_L5min.xlsx','Sheet','FileLvlTotNumOfSegs'); %by file total numbers
DurTotsTab_L5 = readtable('TotVocDurSummaries_0IviMerged_ChnAdOnly_L5min.xlsx','Sheet','TotDurByVocType'); %by voc type total duration
DurDataTab_L5 = readtable('TotVocDurSummaries_0IviMerged_ChnAdOnly_L5min.xlsx','Sheet','FileLvlTotDurOfSegs'); %by file total duration

%read in tables: H5
NumTotsTab_H5 = readtable('TotVocNumsSummaries_0IviMerged_ChnAdOnly_H5min-AllAd.xlsx','Sheet','TotNumByVocType'); %numbers data table (totals by voc type)
NumDataTab_H5 = readtable('TotVocNumsSummaries_0IviMerged_ChnAdOnly_H5min-AllAd.xlsx','Sheet','FileLvlTotNumOfSegs'); %by file total numbers
DurTotsTab_H5 = readtable('TotVocDurSummaries_0IviMerged_ChnAdOnly_H5min-AllAd.xlsx','Sheet','TotDurByVocType'); %by voc type total duration
DurDataTab_H5 = readtable('TotVocDurSummaries_0IviMerged_ChnAdOnly_H5min-AllAd.xlsx','Sheet','FileLvlTotDurOfSegs'); %by file total duration

%get data in plottable form: Tab_barplot has first column for L5 and second column for H5. Rows are for CHNSP, CHNNSP, and AN, in that order.
[NumTab_barplot,H_AnnotTotNums,H_AnnotList,Yvars_boxcht_Nums,ClrGrp_boxcht_Nums,Xvars_boxcht_Nums] ...
                                                            = GetValDataToPlt(NumTotsTab_L5,NumTotsTab_H5,NumDataTab_L5,NumDataTab_H5,'Num');
[DurTab_barplot,H_AnnotTotDurs,~,Yvars_boxcht_Durs,ClrGrp_boxcht_Durs,Xvars_boxcht_Durs] ...
                                                            = GetValDataToPlt(DurTotsTab_L5,DurTotsTab_H5,DurDataTab_L5,DurDataTab_H5,'Dur');
                     
% Create figure: Number of vocs plots
figure1 = figure('PaperType','<custom>','PaperSize',[34 12.5],'Color',[1 1 1]);
%A: Bar plots
axes1 = axes('Parent',figure1,'Position',[0.0432972522897587 0.11 0.251457119067444 0.815]); hold(axes1,'on');
GetValDataBarPlots(NumTab_barplot,H_AnnotTotNums,ValdataClrs,H5AnnotClrs) %plot using function
ylabel('Total number of vocalisations'); xlabel('Segment label'); title('A');
axis(axes1,'tight'); hold(axes1,'off');
set(axes1,'FontSize',24,'XTick',[1 2 3],'XTickLabel',{'ChSp','ChNsp','Ad'});
legend(['L5';'H5';H_AnnotList],'Position',[0.195524079601525 0.817989292805582 0.0976269775187344 0.0974178403755869],'NumColumns',3);

%B: box chart for L5 and H5
axes2 = axes('Parent',figure1,'Position',[0.39247903317284 0.11 0.251457119067444 0.815]); hold(axes2,'on');
GetValDataBoxCht(2*Xvars_boxcht_Nums,Yvars_boxcht_Nums,ClrGrp_boxcht_Nums,ValdataClrs)
ylabel({'Total number of vocalisations','(recording day-level)'}); xlabel('Segment label'); title('B');
hold(axes2,'off'); set(axes2,'FontSize',24,'XTick',2*[1 2 3],'XTickLabel',{'ChSp','ChNsp','Ad'},'YGrid','on','YMinorGrid','on', ...
    'YMinorTick','on','YTick',[0 100 200 300 400 500]);
legend({'L5','H5'},'Position',[0.588169728313625 0.847773896342483 0.0505828476269775 0.0663145539906104]);

%C: box charts for annotations
axes3 = axes('Parent',figure1,'Position',[0.743217849859419 0.11 0.251457119067444 0.815]); hold(axes3,'on');
GetH5AnnotBoxCht(NumDataTab_H5,'Num')
ylabel({'Total number of vocalisations','(recording day-level)'}); xlabel('Annotation'); title('C');
hold(axes3,'off');
set(axes3,'FontSize',24,'XTick',[1 2 3 4 5 6 7],'XTickLabel',{'C','X','R','L','T','U','N'},'YGrid','on','YMinorGrid','on','YMinorTick','on','YTick',...
    [0 100 200 300 400 500]);



% Create figure: Total durations
figure1 = figure('PaperType','<custom>','PaperSize',[34 12.5],'Color',[1 1 1]);
%A: Bar plots
axes1 = axes('Parent',figure1,'Position',[0.0432972522897587 0.11 0.251457119067444 0.815]); hold(axes1,'on');
GetValDataBarPlots(DurTab_barplot,H_AnnotTotDurs,ValdataClrs,H5AnnotClrs) %plot using function
ylim(axes1,[0 20400]); ylabel('Total duration of vocalisations (s)'); xlabel('Segment label'); title('A');
axis(axes1,'tight'); hold(axes1,'off');
set(axes1,'FontSize',24,'XTick',[1 2 3],'XTickLabel',{'ChSp','ChNsp','Ad'});
legend(['L5';'H5';H_AnnotList],'Position',[0.188920901694227 0.816342762756411 0.0758333333333333 0.0983412322274881],'NumColumns',3);

%B: box chart for L5 and H5
axes2 = axes('Parent',figure1,'Position',[0.39247903317284 0.11 0.251457119067444 0.815]); hold(axes2,'on');
GetValDataBoxCht(2*Xvars_boxcht_Durs,Yvars_boxcht_Durs,ClrGrp_boxcht_Durs,ValdataClrs)
ylim(axes2,[0 450]); ylabel({'Total duration of vocalisations (s)','(recording day-level)'}); 
xlabel('Segment label'); title('B');
hold(axes2,'off'); set(axes2,'FontSize',24,'XTick',2*[1 2 3],'XTickLabel',{'ChSp','ChNsp','Ad'},'YGrid','on','YMinorGrid','on', ...
    'YMinorTick','on','YTick',[0 100 200 300 400 500]);
legend({'L5','H5'},'Position',[0.586273652127121 0.878561505091357 0.0560416666666668 0.0355450236966824]);

%C: box charts for annotations
axes3 = axes('Parent',figure1,'Position',[0.743217849859419 0.11 0.251457119067444 0.815]); hold(axes3,'on');
GetH5AnnotBoxCht(DurDataTab_H5,'Dur')
ylabel({'Total duration of vocalisations (s)','(recording day-level)'}); xlabel('Annotation'); title('C');
hold(axes3,'off');
set(axes3,'FontSize',24,'XTick',[1 2 3 4 5 6 7],'XTickLabel',{'C','X','R','L','T','U','N'},'YGrid','on','YMinorGrid','on','YMinorTick','on','YTick',...
    [0 100 200 300 400 500]);


%----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%FUNCTIONS USED
%-----------------------------------------------------------------------------------------------
%This function takes in tables with relevant data tables and outputs data in plottable form
% Inputs: -TotsTab_VocType_H5, TotsTab_VocType_L5: totals (duration or numbers) of vocs by voctype (and annotation type, for human labelled data), 
%                                                  for both L5 and H5
%         -TotsTab_FileLvl_H5, TotsTab_FileLvl_L5: similar totals for CHNSP, CHNNSP, CHN, AN (and total of all key segments + totals by annotation 
%                                                  type, for H5) at the file level
%         -NumOrDur: string specifying whether we are looking at total durations or total numbers of vocs
% 
% Outputs: -Tab_barplot: table with data for bar plot. Contains totals for CHNSP, CHNNSP, and AN (in that order) for each age. Here, the 
%                        1st col for L5, 2nd col for H5. The x axis is speaker label (CHNSP, CHNNSP, AN; in that order), and in each group, there is L5 and H5.
%                        That is, each column is L5 or H5, and each row is a specific speaker label. 
%          -H_AnnotTots: The totals for each type of human listener annotation (for bars inside the main bars--CHNSP, CHNNSP, AN--for H5 data)
%          -H_AnnotList: List of human listener annotations.
%          -Yvars_boxcht, ClrGrp_boxcht,Xvars_boxcht: data for boxchart. Yvars is the actual series of voc totals or total durations for each day-long 
%                  recording. This goes into computing the details for the boxchart. ClrGrp and Xvars are vectors of the same size as Yvars that are used
%                  to determine group the data by colour (validation data type, in this case), and into groups along the x axis (speaker label:CHNSP, 
%                  CHNNSP, AN, in this case).
function [Tab_barplot,H_AnnotTots,H_AnnotList,Yvars_boxcht,ClrGrp_boxcht,Xvars_boxcht] ...
                                            = GetValDataToPlt(TotsTab_VocType_L5,TotsTab_VocType_H5,TotsTab_FileLvl_L5,TotsTab_FileLvl_H5,NumOrDur)

    %generate table for plotting (in order of CHNSP, CHNNSP, AN)
    Tab_barplot = [GetVecForBarPlots(TotsTab_VocType_L5) GetVecForBarPlots(TotsTab_VocType_H5)]; 
    H_AnnotTots = TotsTab_VocType_H5.Totals; %get totals by annotation type (for bars within the main H5 bar)
    H_AnnotList = TotsTab_VocType_H5.H_Annots; %get list of human listener annotations from table
    
    if ~isequal(H_AnnotList,{'C','X','R','L','T','U','N'}') %checks!
        error('List of human listener annotations is not in the expected order. Need to adapt code')
    end

    [Yvars_boxcht_L5, ClrGrp_boxcht_L5, Xvars_boxcht_L5] = GetVecsForBoxPlots(TotsTab_FileLvl_L5, NumOrDur, 1);
    [Yvars_boxcht_H5, ClrGrp_boxcht_H5, Xvars_boxcht_H5] = GetVecsForBoxPlots(TotsTab_FileLvl_H5, NumOrDur, 2);

    Yvars_boxcht = [Yvars_boxcht_L5;Yvars_boxcht_H5]; %concatenate so this info can together be used to plot the boxchart
    ClrGrp_boxcht = [ClrGrp_boxcht_L5; ClrGrp_boxcht_H5];
    Xvars_boxcht = [Xvars_boxcht_L5; Xvars_boxcht_H5];
end

%-----------------------------------------------------------------------------------------------
%This function takes in tables with validation data and converts to a vector for bar plot. So, the input tab is the L5 or H5 table with totals by voc type.
%The output is a column vector with total for CHNSP, CHNNSP, and AN, in that order, as rows.
function BarVec = GetVecForBarPlots(IpTab)

    %convert to form for bar chart. These vectors for L5 and H5 are then concatenated to form the array for bar plots
    BarVec = [sum(IpTab.Totals(contains(IpTab.SpkrLvlLabels,'CHNSP'))); 
                sum(IpTab.Totals(contains(IpTab.SpkrLvlLabels,'CHNNSP')));  
                sum(IpTab.Totals(contains(IpTab.SpkrLvlLabels,'AN')))];

end

%-----------------------------------------------------------------------------------------------
%This function takes in tables with validation data and converts to a vector for box plot. So, the input tab is the L5 or H5 table with totals by voc type
% (and by annotation type, for H5) at the file level.
% Other inputs are the string to identify whether this is duration or voc numbers data (NumOrDur) and the relevant code to identify whether the data
% is from H5 or L5 (ValdataCode; goes into constructing ClrGrp_boxcht).
%The outputs are column vectors with the Y variables for the box chart (totals by CHNSP, CHNNSP, and AN), the list of variables to group by colour 
% (whether data is from L5 or H5), and the list of X variables (CHNSP, CHNNSP, AN).
function [Yvars_boxcht, ClrGrp_boxcht, Xvars_boxcht] = GetVecsForBoxPlots(TotsTab_FileLvl, NumOrDur, ValdataCode)

    ReqVarNames = strcat(NumOrDur,'_',{'CHNSP','CHNNSP','AN'}); %get set of required variable names
    Yvars_boxcht = []; Xvars_boxcht = [];  %initialise matrices to store things for boxchart plotting
    for i = 1:numel(ReqVarNames) %go through list of var names
        Yvars_boxcht = [Yvars_boxcht; TotsTab_FileLvl.(ReqVarNames{i})]; %populate the data for the y coords for boxchart; this is a column vector
        Xvars_boxcht = [Xvars_boxcht; i*ones(size(TotsTab_FileLvl.(ReqVarNames{i})))];  % similarly for the data to separate the boxcharts along the x axis; 
        % Each unique x axis point is indexed by i
    end

    ClrGrp_boxcht = ValdataCode*ones(size(Xvars_boxcht)); %the vector to group by colour: H5 or L5, so initialise the array and populate with 
    % corresponding code. 1 = L5, 2 = H5
end

%-----------------------------------------------------------------------------------------------
%This function takes in tables with data in plottable form and outputs bar plots showing total numbers or duration of key segment types and (for human-listener
% labelled data), annotation types.
% Inputs: -Ytab: totals (duration or numbers) of vocs by validation data type and speaker label. Each row is an speaker label and each columns is the totals for 
%               that speaker label for a given validation data type. The way this is set up, the first column is L5 and second column is H5; and the rows are
%               CHNSP, CHNNSP, and AN
%         -H5_AnnotTots: List of totals by annotation (for H5 data).
%         -ValdataClrs,H5AnnotClrs: Colours for L5 and H5; and for the list of annotations.
function [] = GetValDataBarPlots(Ytab,H5_AnnotTots,ValdataClrs,H5AnnotClrs)

   bp1 = bar(1:height(Ytab), Ytab,'BarWidth',1,'EdgeColor','k','LineWidth',0.5); %plot H5 and L5 bars for CHNSP, CHNNSP, and AN
   bp1(1).FaceColor = ValdataClrs(1,:); %set colours
   bp1(2).FaceColor = ValdataClrs(2,:);

   H5_AnnotTotsInds = {[1 2]; [3 4]; [5 6 7]}; %partition the H5 annotations in order of which H5 bar they go inside. So, the H5 (and L5) bars are
   %plotted in the order CHNSP, CHNNSP, and AN. The H5 Annotations are in the order {'C','X','R','L','T','U','N'}. Som C and X get plotted into CHNSP,
   % so they go into teh first partition (indiced 1 and 2) and so on and so forth.

   for i = 1:numel(bp1(2).XEndPoints) %go through the list of H5 bars (H5 is the second set of bars)
       %the ith x end point in bp1(2) corresponds to the ith speaker type
       %(CHNSP, CHNNSP, or AN). So, we can plot the annotation bars inside
       %the relevant H5 bars
       bp_i = bar(bp1(2).XEndPoints(i), H5_AnnotTots(H5_AnnotTotsInds{i}),'EdgeColor', 'k', 'BarWidth',1,'GroupWidth',0.25,'LineWidth',0.5);
       for j = 1:numel(H5_AnnotTotsInds{i}) %set the face colour for each internal bar, using bp_i
           bp_i(j).FaceColor = H5AnnotClrs(H5_AnnotTotsInds{i}(j),:);
       end
   end
end

%-----------------------------------------------------------------------------------------------
%This function takes in tables with data in plottable form and outputs box charts for total number or duration of key segments (CHNSP, CHNNSP, and AN; 
% totals at the rec day level), for L5 and H5 data
% Inputs: -Xvars_SegType,Yvars_Tots,ClrGrp_ValDataType: vectors with info about the segment type (X  axis), totals at rec day level 
%                                                           (duration or numbers), and whether data is from L5 or H5. Goes into box plot. 
%         -ValdataClrs: Colours indicating whether L5 or H5
function [] = GetValDataBoxCht(Xvars_SegType,Yvars_Tots,ClrGrp_ValDataType,ValdataClrs)

    b1 = boxchart(Xvars_SegType,Yvars_Tots,'GroupByColor',ClrGrp_ValDataType,'MarkerStyle','.','MarkerSize',15,...
        'BoxMedianLineColor','k','LineWidth',1.5,'BoxWidth',0.5,'BoxFaceAlpha',0.7,'Notch','on'); %plot box charts
    for i = 1:numel({'L5','H5'}) %set rest of box charat properties; the order of colours is set by the order of appearance of the unique
        %colour group items
        b1(i).BoxFaceColor = ValdataClrs(i,:);
        b1(i).WhiskerLineColor = 'k';%ReqClrs(i,:);
        %b1(i).BoxMedianLineColor = 'k';%ReqClrs(i,:);
        b1(i).MarkerColor = ValdataClrs(i,:);
        b1(i).BoxEdgeColor = 'k';%ReqClrs(i,:);
    end
end

%-----------------------------------------------------------------------------------------------
%This function takes in tables with data in plottable form and outputs box charts for total number or duration of key segments (at the rec day level), grouped by age.
% Inputs: The input table with file level totals of total duration or number of vocs by annotation type (IpTab), the string to identify whether we are
% dealinhg with duration or total number of vocs (NumOrDur)
function [] = GetH5AnnotBoxCht(IpTab,NumOrDur)

    ReqVarNames = strcat(NumOrDur,'_',{'C','X','R','L','T','U','N'}); %get set of required variable names
    Yvars = []; Xvars = []; %initialise matrices to store things for boxchart plotting
    for i = 1:numel(ReqVarNames) %go through list of var names
        Yvars = [Yvars; IpTab.(ReqVarNames{i})]; %populate the data for the y coords for boxchart; this is a column vector
        Xvars = [Xvars; i*ones(size(IpTab.(ReqVarNames{i})))];  % similarly for the data to separate the boxcharts along the x axis; 
        % Each unique x axis point is indexed by i
    end

    %Note that we are using Xvars for both the axis and colour grouping
    b1 = boxchart(Xvars,Yvars,'MarkerStyle','.','MarkerSize',15,...
        'BoxMedianLineColor','k','LineWidth',1.5,'BoxWidth',0.3,'BoxFaceAlpha',0.3,'Notch','on',...
        'WhiskerLineColor','k','BoxEdgeColor','k','BoxFaceColor','k','MarkerColor','k'); %plot box charts
end

