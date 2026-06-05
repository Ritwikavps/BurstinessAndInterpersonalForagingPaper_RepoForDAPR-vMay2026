clear; clc;

%@authorinfo; Jan 2026
% This is part of additional plotting code being written for the Burstiness paper in response to reviewer comments. Here, I plot results of the prev. 2 IEI analyses to show the
% effect of taking more history into account.

%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLEASE CHANGE PATHS APPROPRIATELY
DataPath = '~/Basepath/Data/ResultsTabs/ResponseAnalyses/';
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%read in tables, filter data, etc
cd(DataPath)
DataTab_2IEI_5s = readtable('Rev_RespEff_W_Prev2StSizCtrl_not_sum_5sRespWin_VarsScaleLog_CorpusLvl_IviOnly_CI99_9prc.csv'); %results from prev 2 IEI supplemental analyses
%This table should only have 5 s response window cuz that's all we are testing, therefore, ERROR CHECK.
u_RespWin = unique(DataTab_2IEI_5s.RespWin_Seconds); 
if numel(u_RespWin) == 5
    error('The 2 prev. IEI robustness check should only have 5 s response window')
end

%read in previous iei (only one prev iei) control analyses results and filter for the 5 s resp window (u_RespWin = 5).
DataTab_1IEI_5s = readtable('RespEff_W_PrevStSizCtrl_VarsScaleLog_CorpusLvl_IviOnly_CI99_9prc.csv');
DataTab_1IEI_5s = DataTab_1IEI_5s(DataTab_1IEI_5s.RespWin_Seconds == u_RespWin,:);

%set up function inputs for plotting
LENAClrs = [0 0.4470 0.7410; 0 0 0]; %colours for each speaker type for lena data: first is infant speaker, second is adult speaker, much like in RespTypeStr
RespTypeStr = {'ANRespToCHNSP','CHNSPRespToAN'}; 
RespTypeLegend = {'ChSp','Ad'};
ValDataClrs = [119 39 89; 63 139 156; 163 179 96]/256; %line colours for each data type (see list below)
ValDataTypeList = {'LENA5min','Hum-AllAd','HumChildDirAdOnly'};
ValDataLegend = {'L: 5 min','H: All Adult','H: Child-directed Adult'};


%% Plotting
figure1 = figure('PaperType','<custom>','PaperSize',[20 11.25],'WindowState','maximized','Color',[1 1 1]); % Create figure

%LENA daylong data, prev. iei beta-----------------------------------------------------------------------------------------------------------
YVarToPlot = 'PrevSt_Beta'; %Prev (1) IEI correlation
axes1 = axes('Parent',figure1,'Position',[0.138597883597883 0.495962866312472 0.213405797101448 0.340774229328626]); hold(axes1, 'on'); 
%NaN plotting for legend -----------------------------
for i_plt = 1:height(LENAClrs) %1 prev IEI model
    plot(NaN,NaN,'Marker','o','LineStyle','-','LineWidth',1.5,'Color',LENAClrs(i_plt,:),'MarkerFaceColor',LENAClrs(i_plt,:))
end
for i_plt = 1:height(LENAClrs) %2 prev IEI model
    plot(NaN,NaN,'Marker','s','LineStyle',':','LineWidth',2,'Color',LENAClrs(i_plt,:),'MarkerFaceColor',[1 1 1])
end
%1 prev IEI model-------------------------------------
X_Offset = [-0.15 -0.05]; %staggering the x values a bit from the actual infantage_months for viz purposes. This is the offset amount for the 1 previous IEI model
PlotPrev2IeiEffLena(DataTab_1IEI_5s,RespTypeStr,X_Offset,YVarToPlot, ...
    'o','-',1.5,LENAClrs,'auto') %marker type, line type, line width, line colour, marker face color (for error bar style plot)
%2 prev IEI model-------------------------------------
X_Offset = [0.05 0.15]; %offset amounts for the 2 previous IEI model
PlotPrev2IeiEffLena(DataTab_2IEI_5s,RespTypeStr,X_Offset,YVarToPlot, ...
    's',':',2,LENAClrs,[1 1 1])
ylabel('Previous IEI effect'); title('A'); %labels
xlim(axes1,[2.45 18.55]); ylim(axes1,[0.038 0.3344]); hold(axes1,'off'); %limits and hold off
set(axes1,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XTick',[3 6 9 18],'XTickLabel',{'','','',''},'YGrid','on',...
    'YLimitMethod','tight','YMinorGrid','on','YMinorTick','on','YTick',[0.1 0.2 0.3],'ZLimitMethod','tight');
legend([strcat(RespTypeLegend,', Prev. 1 IEI model') strcat(RespTypeLegend,', Prev. 2 IEI model')], ...
    'Position',[0.0350529100529101 0.89624647490281 0.363740061946883 0.0807106574474658],'NumColumns',2); % Create legend


%LENA daylong data, prev. 2 iei beta-----------------------------------------------------------------------------------------------------------
YVarToPlot = 'Prev2St_Beta'; %Prev (2) IEI correlation (therefore, only for 2 IEI model)
axes2 = axes('Parent',figure1,'Position',[0.138597883597883 0.109996944138859 0.213405797101448 0.340774229328626]); hold(axes2, 'on'); 
X_Offset = [-0.15 0.15]; %x offset for staggering but we only need the 2 IEI model
PlotPrev2IeiEffLena(DataTab_2IEI_5s,RespTypeStr,X_Offset,YVarToPlot, ...
    's',':',2,LENAClrs,[1 1 1])
ylabel(['Previous-to-previous';'IEI effect          ']); xlabel('Infant age (months)'); title('B'); %labels
xlim(axes2,[2.45 18.55]); ylim(axes2,[0.038 0.3344]); hold(axes2,'off'); %limits
set(axes2,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XTick',[3 6 9 18],'YGrid','on','YLimitMethod','tight','YMinorGrid','on',...
    'YMinorTick','on','YTick',[0.1 0.2 0.3],'YTickLabel',{'0.1','0.2','0.3'},'ZLimitMethod','tight');


%LENA daylong data, marg Rsq-----------------------------------------------------------------------------------------------------------
YVarToPlot = 'MargR2_PrevStMdl'; %marginal R2 value (since we are only comparing different fixed effects; also note that some validation data has conditional Rsq that does not
%converge; see relevant table)
axes3 = axes('Parent',figure1,'Position',[0.708789970094306 0.548148148148148 0.213405797101448 0.289249480503607]); hold(axes3, 'on'); 
%1 prev IEI model-------------------------------------
X_Offset = [-0.15 -0.05]; %x offset for staggering for prev (1) Iei model
PlotRsqLena(DataTab_1IEI_5s,RespTypeStr,X_Offset,YVarToPlot, ...
    'o','-',1.5,LENAClrs,LENAClrs) %marker type, line type, line width, line colour, marker face color (for plot using plot(), and not errorbar())
%2 prev IEI model-------------------------------------
X_Offset = [0.05 0.15];
PlotRsqLena(DataTab_2IEI_5s,RespTypeStr,X_Offset,YVarToPlot, ...
    's',':',2,LENAClrs,[1 1 1; 1 1 1])
ylabel('Marginal R^2'); xlabel('Infant age (months)'); title('E'); %labels
xlim(axes3,[2.45 18.55]); ylim(axes3,[0 0.25]); hold(axes3,'off')
set(axes3,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XTick',[3 6 9 18],'YGrid','on','YLimitMethod','tight','YMinorGrid','on',...
    'XMinorTick','on','YMinorTick','on','YTick',[0 0.1 0.2]);


%Validation data, prev 1 iei beta-----------------------------------------------------------------------------------------------------------
YVarToPlot = 'PrevSt_Beta'; %Prev (1) IEI correlation
Ctr = 0; %for the legend
axes4 = axes('Parent',figure1,'Position',[0.368469059121227 0.495962866312471 0.213405797101447 0.340774229328626]); hold(axes4,'on'); 
%dummy plotting for legend---------------------------
for j = 1:numel(ValDataTypeList) %for prev 1 IEI model
    plot(NaN,NaN,'o','LineWidth',1.5,'MarkerFaceColor',ValDataClrs(j,:),'MarkerEdgeColor',ValDataClrs(j,:),'MarkerSize',10)
    Ctr = Ctr + 1; %update Ctr
    LegendCell{Ctr,1} = strcat(ValDataLegend{j},', Prev. 1 IEI model'); %get legend string
end
for j = 1:numel(ValDataTypeList) %dummy plotting for prev 2 IEI model
    plot(NaN,NaN,'s','LineWidth',2,'MarkerFaceColor',[1 1 1],'MarkerEdgeColor',ValDataClrs(j,:),'MarkerSize',10) 
    Ctr = Ctr + 1; %update Ctr
    LegendCell{Ctr,1} = strcat(ValDataLegend{j},', Prev. 2 IEI model'); %get legend string
end
%1 prev IEI model-------------------------------------
XCntrs = [1 2]; X_Offset = [-0.15 -0.09 -0.03]; %For val data, we plot these as two groups (CHNSP, AN; given by XCntrs) and the stagger for viz is given by X_Offset
for i = 1:numel(RespTypeStr) %loop through response type and validation data type
    for j = 1:numel(ValDataTypeList)
        PlotPrev2IeiEffValData(DataTab_1IEI_5s,RespTypeStr{i},ValDataTypeList{j},XCntrs(i)+X_Offset(j),YVarToPlot, ...
            'o',1.5,ValDataClrs(j,:),'auto') %marker type,LineWdth,line colour, marker face colour (errorbar style plot)
    end
end
%2 prev IEI model-------------------------------------
X_Offset = [0.03 0.09 0.15]; %x offsets for 2 prev IEI model
for i = 1:numel(RespTypeStr)
    for j = 1:numel(ValDataTypeList)
        PlotPrev2IeiEffValData(DataTab_2IEI_5s,RespTypeStr{i},ValDataTypeList{j},XCntrs(i)+X_Offset(j),YVarToPlot, ...
            's',2,ValDataClrs(j,:),[1 1 1]) %marker type,LineWdth,line colour, marker face colour (errorbar style plot)
    end
end
title('C'); % Create title
xlim(axes4,[0.75 2.25]); ylim(axes4,[0.038 0.3344]); hold(axes4,'off'); %limites and hold off
set(axes4,'FontSize',24,'XGrid','on','XLimitMethod','tight','XTick',[1 2],'XTickLabel',{'',''},'YGrid','on','YLimitMethod','tight','YMinorGrid','on',...
    'YMinorTick','on','YTick',[0.1 0.2 0.3],'YTickLabel',{'','',''},'ZLimitMethod','tight');
legend(LegendCell,'Position',[0.404953406601352 0.886775555778167 0.564814814814812 0.102595797280593],'NumColumns',2);


%Validation data, prev 2 iei beta-----------------------------------------------------------------------------------------------------------
YVarToPlot = 'Prev2St_Beta'; %Prev (2) IEI correlation, therefore only for the prev 2 IEI model
axes5 = axes('Parent',figure1,'Position',[0.368469059121227 0.109996944138859 0.213405797101447 0.340774229328626]); hold(axes5, 'on') 
XCntrs = [1 2]; X_Offset = [-0.06 0 0.06]; %x value centers and offsets
for i = 1:numel(RespTypeStr) %loop through response type and validation data type
    for j = 1:numel(ValDataTypeList)
        PlotPrev2IeiEffValData(DataTab_2IEI_5s,RespTypeStr{i},ValDataTypeList{j},XCntrs(i)+X_Offset(j),YVarToPlot, ...
            's',2,ValDataClrs(j,:),[1 1 1]) %marker type,LineWdth,line colour, marker face colour (errorbar style plot)
    end
end
xlabel('Vocalization type'); title('D'); %labels
xlim(axes5,[0.75 2.25]); ylim(axes5,[0.038 0.3344]); hold(axes5,'off'); %labels and hold off
set(axes5,'FontSize',24,'XGrid','on','XLimitMethod','tight','XTick',[1 2],'XTickLabel',{'ChSp','Ad'},'YGrid','on','YLimitMethod','tight','YMinorGrid',...
    'on','YMinorTick','on','YTick',[0.1 0.2 0.3],'YTickLabel',{'','',''},'ZLimitMethod','tight');


%Validation data, marg Rsq-----------------------------------------------------------------------------------------------------------
YVarToPlot = 'MargR2_PrevStMdl'; %marginal r squared
axes6 = axes('Parent',figure1,'Position',[0.708789970094306 0.111234567901235 0.213405797101448 0.289249480503607]); hold(axes6, 'on');
%1 prev IEI model-------------------------------------
XCntrs = [1 2]; X_Offset = [-0.15 -0.09 -0.03];
for i = 1:numel(RespTypeStr) %loop through response type and validation data type
    for j = 1:numel(ValDataTypeList)
        PlotRsqValData(DataTab_1IEI_5s,RespTypeStr{i},ValDataTypeList{j},XCntrs(i)+X_Offset(j),YVarToPlot, ...
            'o',1.5,ValDataClrs(j,:),ValDataClrs(j,:)) %marker type,LineWdth,line colour, marker face colour (using plot())
    end
end
%2 prev IEI model-------------------------------------
X_Offset = [0.03 0.09 0.15];
for i = 1:numel(RespTypeStr)
    for j = 1:numel(ValDataTypeList)
        PlotRsqValData(DataTab_2IEI_5s,RespTypeStr{i},ValDataTypeList{j},XCntrs(i)+X_Offset(j),YVarToPlot, ...
            's',2,ValDataClrs(j,:),[1 1 1])
    end
end
ylabel('Marginal R^2'); xlabel('Vocalization type'); title('F'); %labels
xlim(axes6,[0.75 2.25]); ylim(axes6,[0 0.25]); hold(axes6,'off');
set(axes6,'FontSize',24,'XGrid','on','XLimitMethod','tight','XTick',[1 2],'XTickLabel',{'ChSp','Ad'},'YGrid','on','YLimitMethod','tight','YMinorGrid',...
    'on','YMinorTick','on','YTick',[0 0.1 0.2],'ZLimitMethod','tight');


%Annotation: Create line
annotation(figure1,'line',[0.574074074074074 0.574074074074074],[0.0680693069306931 0.852960396039604],...
    'Color',[0.650980392156863 0.650980392156863 0.650980392156863],'LineWidth',2,'LineStyle',':');


%----------------------------------------------------------------------------------------------------------------------------------------------
%Functions used:
%--------------------------------------------------------------------
% This function takes in the table with results from previous (1 or 2) IEI models and plots the previous (1) or previous (2) IEI effect sizes with error bars and specified
% plotting styles (for LENA daylong data)
% 
% Inputs: - IpTab: input table
%         - RespTypeStr: cell array with response types ({'ANRespToCHNSP','CHNSPRespToAN'}); this gets looped through
%         - X_Offset: offset from the infant age value for plot stagger for data viz. This is avector with the same num of elements as RespTypeStr (and is used to loop through
%                     RespTypeStr)
%         - YVarToPlot: name of the column corresponding to the Y variable to plot; string
%         - MkrType, LineType, LineWdth, Clrs, MkrFaceClr: plotting specifications. Clrs is an array where each row is the colour for the ith response type in the RespTypeStr 
%                      cell array, while everything else is a single item common for all the data being plotted (MkrFaceClr can be a string or a 1x3 rgb vector).
function PlotPrev2IeiEffLena(IpTab,RespTypeStr,X_Offset,YVarToPlot,MkrType,LineType,LineWdth,Clrs,MkrFaceClr)

    LENATab = IpTab(strcmp(IpTab.DataType,'LENA'),:); %filter for LENA daylong data

    PvalVar = regexprep(YVarToPlot,'_.*','P'); %get the p value column for the Y var to plot
    if ~all(LENATab.(PvalVar) < 0.001) %check if there are p values grater than 0.001 (in which case, the code needs to be adapted)
        error('There are p values greater than 0.001, must adapt code!')
    end

    for i = 1:numel(X_Offset) %go through the x offset vector (corresponding to the response types: {'ANRespToCHNSP','CHNSPRespToAN'})
        ReqSubTab = LENATab(contains(LENATab.ResponseType,RespTypeStr{i}),:); %filter for response type
        UpperBarVar = regexprep(YVarToPlot,'_.*','CI_Upper'); LwrBarVar = regexprep(YVarToPlot,'_.*','CI_Lwr'); %get upper and lower CI values

        %plot errorbars
        errorbar(ReqSubTab.InfAge_Months+X_Offset(i),ReqSubTab.(YVarToPlot),...
            abs(ReqSubTab.(YVarToPlot) - ReqSubTab.(LwrBarVar)),abs(ReqSubTab.(YVarToPlot) - ReqSubTab.(UpperBarVar)),'Marker',MkrType,'MarkerSize',10,...
            'LineStyle',LineType,'LineWidth',LineWdth,'Color',Clrs(i,:),'MarkerFaceColor',MkrFaceClr);
    end
end


%--------------------------------------------------------------------
% This function takes in the table with results from previous (1 or 2) IEI models and plots the previous (1) or previous (2) IEI effect sizes with error bars and specified
% plotting styles (for validation data)
% 
% Inputs: - IpTab: input table
%         - RespTypeStr: string with response type (e.g., 'ANRespToCHNSP'); this gets looped through outside of this function
%         - DataType: the validation data type (string); this is looped through outside of the function.
%         - XVec: X values to plot (offsets for staggering have already been incorpoated outside of the fn).
%         - YVarToPlot: name of the column corresponding to the Y variable to plot; string
%         - MkrType, LineWdth, Clr, MkrFaceClr: plotting specifications. Everything is a single item for the data being plotted except 
%                           Clr and MkrFaceClr, which can be a string or a 1x3 rgb vector.
function PlotPrev2IeiEffValData(IpTab,RespTypeStr,DataType,XVec,YVarToPlot,MkrType,LineWdth,Clr,MkrFaceClr)

    ValDataTab = IpTab(strcmp(IpTab.DataType,DataType),:); %filter for data type

    PvalVar = regexprep(YVarToPlot,'_.*','P'); %get the p value column for the Y var to plot
    if ~all(ValDataTab.(PvalVar) < 0.001) %check if there are p values grater than 0.001 (in which case, the code needs to be adapted)
        error('There are p values greater than 0.001, must adapt code!')
    end

    ReqSubTab = ValDataTab(contains(ValDataTab.ResponseType,RespTypeStr),:); %subset for the response type
    UpperBarVar = regexprep(YVarToPlot,'_.*','CI_Upper'); LwrBarVar = regexprep(YVarToPlot,'_.*','CI_Lwr'); %get upper and lower CI values

    %plot errorbars
    errorbar(XVec,ReqSubTab.(YVarToPlot),abs(ReqSubTab.(YVarToPlot) - ReqSubTab.(LwrBarVar)),abs(ReqSubTab.(YVarToPlot) - ReqSubTab.(UpperBarVar)), ...
        'Marker',MkrType,'MarkerSize',10,'LineStyle','none','LineWidth',LineWdth,'Color',Clr,'MarkerFaceColor',MkrFaceClr);
end

%--------------------------------------------------------------------
% This function takes in the table with results from previous (1 or 2) IEI models and plots the marginal Rsq using plot() and specified plotting styles (for Lday data)
% 
% Inputs: - IpTab: input table
%         - RespTypeStr: cell array with response types ({'ANRespToCHNSP','CHNSPRespToAN'}); this gets looped through
%         - X_Offset: offset from the infant age value for plot stagger for data viz. This is avector with the same num of elements as RespTypeStr (and is used to loop through
%                     RespTypeStr)
%         - YVarToPlot: name of the column corresponding to the Y variable to plot; string
%         - MkrType, LineType, LineWdth, Clrs, MkrFaceClr: plotting specifications. Clrs and MkrFaceClr are arrays where each row is the colour for the ith response type 
%                      in the RespTypeStr cell array, while everything else is a single item common for all the data being plotted.
function PlotRsqLena(IpTab,RespTypeStr,X_Offset,YVarToPlot,MkrType,LineType,LineWdth,Clrs,MkrFaceClr)

    LENATab = IpTab(strcmp(IpTab.DataType,'LENA'),:);%filter for LENA daylong data

    for i = 1:numel(X_Offset) %go through the x offset vector (corresponding to the response types: {'ANRespToCHNSP','CHNSPRespToAN'})
        ReqSubTab = LENATab(contains(LENATab.ResponseType,RespTypeStr{i}),:); %filter for response type
        
        %plot!
        plot(ReqSubTab.InfAge_Months+X_Offset(i),ReqSubTab.(YVarToPlot),'Marker',MkrType,'MarkerSize',10,...
            'LineStyle',LineType,'LineWidth',LineWdth,'Color',Clrs(i,:),'MarkerFaceColor',MkrFaceClr(i,:));
    end
end

%--------------------------------------------------------------------
% This function takes in the table with results from previous (1 or 2) IEI models and plots the marginal Rsq using plot() and specified plotting styles (for validation data)
% 
% Inputs: - IpTab: input table
%         - RespTypeStr: string with response type (e.g., 'ANRespToCHNSP'); this gets looped through outside of this function
%         - DataType: the validation data type (string); this is looped through outside of the function.
%         - XVec: X values to plot (offsets for staggering have already been incorpoated outside of the fn).
%         - YVarToPlot: name of the column corresponding to the Y variable to plot; string
%         - MkrType, LineWdth, Clr, MkrFaceClr: plotting specifications. Everything is a single item for the data being plotted except 
%                           Clr and MkrFaceClr, which can be a string or a 1x3 rgb vector.
function PlotRsqValData(IpTab,RespTypeStr,DataType,XVec,YVarToPlot,MkrType,LineWdth,Clr,MkrFaceClr)

    ValDataTab = IpTab(strcmp(IpTab.DataType,DataType),:); %filter for data type
    ReqSubTab = ValDataTab(contains(ValDataTab.ResponseType,RespTypeStr),:); %filter for response type

    %plot!
    plot(XVec,ReqSubTab.(YVarToPlot),'Marker',MkrType,'MarkerSize',10,'LineStyle','none','LineWidth',LineWdth,'Color',Clr,'MarkerFaceColor',MkrFaceClr);
end





