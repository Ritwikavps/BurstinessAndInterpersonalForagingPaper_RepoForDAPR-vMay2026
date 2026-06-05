clear; clc;

%Ritwika VPS; Jan 2026
% This is part of additional plotting code being written for the Burstiness paper in response to reviewer comments. Here, I plot response effect results of the prev. 2 IEI 
% analyses vs the previous 1 IEI analyses to show the effect of taking more history into account.

%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLEASE CHANGE PATHS APPROPRIATELY
DataPath = '~/Desktop/GoogleDriveFiles/research/IVFCRAndOtherWorkWithAnne/Pre_registration_followu/Data/ResultsTabs/ResponseAnalyses/';
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
RespTypeStr = {'ANRespToCHNSP','CHNSPRespToAN'}; 
RespTypeLegend = {'ChSp','Ad'};
ValDataClrs = [119 39 89; 63 139 156; 163 179 96]/256; %line colours for each data type (see list below)
ValDataTypeList = {'LENA5min','Hum-AllAd','HumChildDirAdOnly'};
ValDataLegend = {'L: 5 min','H: All Adult','H: Child-directed Adult'};


%% Plotting: LENA daylog data
LdayClr = [0.25 0.25 0.25]; %We are using one colour for the daylong data cuz each subplot will only have the prev 1 and 2 IEI model results for one speaker/response combo
figure1 = figure('PaperType','<custom>','PaperSize',[15.5 10.5],'Color',[1 1 1]); % Create figure

%LENA daylong data, response beta, adult response to infant-----------------------------------------------------------------------------------------------------------
YVarToPlot = 'Response_Beta'; %response beta
axes1 = axes('Parent',figure1,'Position',[0.176968403074295 0.577649090490445 0.312308825006232 0.340774217905932]); hold(axes1, 'on'); 
%Legend plotting--------------------------------------
plot(NaN,NaN,'Marker','o','LineStyle','-','LineWidth',1.5,'Color',LdayClr,'MarkerFaceColor',LdayClr) %1 prev IEI model
plot(NaN,NaN,'Marker','s','LineStyle',':','LineWidth',2,'Color',LdayClr,'MarkerFaceColor',[1 1 1]) %2 prev IEI model
%1 prev IEI model-------------------------------------
X_Offset = [-0.15]; %staggering the x values a bit from the actual infantage_months for viz purposes. This is the offset amount for the 1 previous IEI model
PlotRespEffLena(DataTab_1IEI_5s,'ANRespToCHNSP',X_Offset,YVarToPlot, ...
    'o','-',1.5,LdayClr,'auto') %marker type, line type, line width, line colour, marker face color (for error bar style plot)
%2 prev IEI model-------------------------------------
X_Offset = [0.15]; %offset amounts for the 2 previous IEI model
PlotRespEffLena(DataTab_2IEI_5s,'ANRespToCHNSP',X_Offset,YVarToPlot, ...
    's',':',2,LdayClr,[1 1 1])
ylabel('Effect of adult response on infant IEI length (\beta)'); title('A'); %labels
xlim(axes1,[2.55 18.45]); ylim(axes1,[-0.215 -0.037]); %axes limits
hold(axes1,'off'); 
set(axes1,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XTick',[3 6 9 18],'XTickLabel',{'','','',''},'YGrid','on',...
    'YLimitMethod','tight','YMinorGrid','on','YMinorTick','on','ZLimitMethod','tight');
legend({'Prev. 1 IEI model', 'Prev. 2 IEI model'}, ...
    'Position',[0.182060664015474 0.584158415841584 0.184429163351035 0.0761249618133372]); % Create legend


%LENA daylong data, response beta, infant response to adult-----------------------------------------------------------------------------------------------------------
YVarToPlot = 'Response_Beta'; %response beta
axes2 = axes('Parent',figure1,'Position',[0.176968403074295 0.179306930693069 0.312308825006232 0.340774217905932]); hold(axes2, 'on'); 
%1 prev IEI model-------------------------------------
X_Offset = [-0.15]; %staggering the x values a bit from the actual infantage_months for viz purposes. This is the offset amount for the 1 previous IEI model
PlotRespEffLena(DataTab_1IEI_5s,'CHNSPRespToAN',X_Offset,YVarToPlot, ...
    'o','-',1.5,LdayClr,'auto') %marker type, line type, line width, line colour, marker face color (for error bar style plot)
%2 prev IEI model-------------------------------------
X_Offset = [0.15]; %offset amounts for the 2 previous IEI model
PlotRespEffLena(DataTab_2IEI_5s,'CHNSPRespToAN',X_Offset,YVarToPlot, ...
    's',':',2,LdayClr,[1 1 1])
ylabel('Effect of infant response on adult IEI length (\beta)'); xlabel({'Infant age (months)'}); title('C'); %labels
xlim(axes2,[2.55 18.45]); ylim(axes2,[-0.215 -0.037]); %limits
hold(axes2,'off'); %limits and hold off
set(axes2,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XTick',[3 6 9 18],'XTickLabel',{'3','6','9','18'},'YGrid','on',...
    'YLimitMethod','tight','YMinorGrid','on','YMinorTick','on','ZLimitMethod','tight');


%LENA daylong data, Rsq, adult response to infant-----------------------------------------------------------------------------------------------------------
YVarToPlot = 'Rsq_RespMdl'; %R2 value 
axes3 = axes('Parent',figure1,'Position',[0.6302658974532 0.577649090490445 0.312308825006234 0.340774217905932]); hold(axes3, 'on'); 
%1 prev IEI model-------------------------------------
X_Offset = [-0.15]; %x offset for staggering for prev (1) Iei model
PlotRsqLena(DataTab_1IEI_5s,'ANRespToCHNSP',X_Offset,YVarToPlot, ...
    'o','-',1.5,LdayClr,LdayClr) %marker type, line type, line width, line colour, marker face color (for plot using plot(), and not errorbar())
%2 prev IEI model-------------------------------------
X_Offset = [0.15];
PlotRsqLena(DataTab_2IEI_5s,'ANRespToCHNSP',X_Offset,YVarToPlot, ...
    's',':',2,LdayClr,[1 1 1; 1 1 1])
ylabel('R^2'); title('B'); %labels
xlim(axes3,[2.55 18.45]); ylim(axes3,[0.0016 0.0058]); %limites
hold(axes3,'off')
% Set the remaining axes properties
set(axes3,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XTick',[3 6 9 18],'XTickLabel',{'','','',''},'YGrid','on',...
    'YLimitMethod','tight','YMinorGrid','on','YMinorTick','on');


%LENA daylong data, Rsq, infant response to adult-----------------------------------------------------------------------------------------------------------
YVarToPlot = 'Rsq_RespMdl'; %R2 value 
axes4 = axes('Parent',figure1,'Position',[0.630265897453202 0.179306930693069 0.312308825006234 0.340774217905932]); hold(axes4, 'on'); 
%1 prev IEI model-------------------------------------
X_Offset = [-0.15]; %x offset for staggering for prev (1) Iei model
PlotRsqLena(DataTab_1IEI_5s,'CHNSPRespToAN',X_Offset,YVarToPlot, ...
    'o','-',1.5,LdayClr,LdayClr) %marker type, line type, line width, line colour, marker face color (for plot using plot(), and not errorbar())
%2 prev IEI model-------------------------------------
X_Offset = [0.15];
PlotRsqLena(DataTab_2IEI_5s,'CHNSPRespToAN',X_Offset,YVarToPlot, ...
    's',':',2,LdayClr,[1 1 1; 1 1 1])
ylabel('R^2'); xlabel('Infant age (months)'); title('D'); %labels
xlim(axes4,[2.55 18.45]); ylim(axes4,[0.0016 0.0058]); %limites
hold(axes4,'off');
set(axes4,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XTick',[3 6 9 18],'YGrid','on','YLimitMethod','tight','YMinorGrid','on',...
    'YMinorTick','on');



%% Plotting: Validation data
figure2 = figure('PaperType','<custom>','PaperSize',[19 9.5],'Color',[1 1 1]); % Create figure

%Validation data, prev 1 iei beta-----------------------------------------------------------------------------------------------------------
YVarToPlot = 'Response_Beta'; %Prev (1) IEI correlation
Ctr = 0; %for the legend
axes1 = axes('Parent',figure2,'Position',[0.149841269841269 0.132900763358779 0.33465909090909 0.65793893129771]); hold(axes1,'on'); 
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
        PlotRespEffValData(DataTab_1IEI_5s,RespTypeStr{i},ValDataTypeList{j},XCntrs(i)+X_Offset(j),YVarToPlot, ...
            'o',1.5,ValDataClrs(j,:),'auto') %marker type,LineWdth,line colour, marker face colour (errorbar style plot)
    end
end
%2 prev IEI model-------------------------------------
X_Offset = [0.03 0.09 0.15]; %x offsets for 2 prev IEI model
for i = 1:numel(RespTypeStr)
    for j = 1:numel(ValDataTypeList)
        PlotRespEffValData(DataTab_2IEI_5s,RespTypeStr{i},ValDataTypeList{j},XCntrs(i)+X_Offset(j),YVarToPlot, ...
            's',2,ValDataClrs(j,:),[1 1 1]) %marker type,LineWdth,line colour, marker face colour (errorbar style plot)
    end
end
ylabel('Effect of response on IEI length (\beta)'); xlabel('Vocalization type'); title('A'); %labels
xlim(axes1,[0.8 2.2]); ylim(axes1,[-0.35 0.195]); %limits
hold(axes1,'off');
set(axes1,'FontSize',24,'XGrid','on','XLimitMethod','tight','XTick',[1 2],'XTickLabel',{'ChSp','Ad'},'YGrid','on','YLimitMethod','tight','YMinorGrid',...
    'on','YMinorTick','on','ZLimitMethod','tight');
legend(LegendCell,'Position',[0.247545999193947 0.858212932318756 0.564814814814813 0.126717557251908],'NumColumns',2);


%Validation data, marg Rsq-----------------------------------------------------------------------------------------------------------
YVarToPlot = 'Rsq_RespMdl'; %marginal r squared
axes2 = axes('Parent',figure2,'Position',[0.590182178932177 0.132900763358779 0.334659090909091 0.65793893129771]); hold(axes2, 'on');
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
ylabel({'R^2'}); xlabel('Vocalization type'); title('B');
xlim(axes2,[0.8 2.2]); ylim(axes2,[0.0001 0.0085]);
hold(axes2,'off');
set(axes2,'FontSize',24,'XGrid','on','XLimitMethod','tight','XTick',[1 2],'XTickLabel',{'ChSp','Ad'},'YGrid','on','YLimitMethod','tight','YMinorGrid',...
    'on','YMinorTick','on','YTick',[0.002 0.004 0.006 0.008],'ZLimitMethod','tight');


%----------------------------------------------------------------------------------------------------------------------------------------------
%Functions used:
%--------------------------------------------------------------------
% This function takes in the table with results from previous (1 or 2) IEI models and plots the previous (1) or previous (2) IEI effect sizes with error bars and specified
% plotting styles (for LENA daylong data)
% 
% Inputs: - IpTab: input table
%         - RespTypeStr: string denoting response type (e.g., 'ANRespToCHNSP','CHNSPRespToAN')
%         - X_Offset: offset from the infant age value for plot stagger for data viz. This is avector with the same num of elements as RespTypeStr (and is used to loop through
%                     RespTypeStr)
%         - YVarToPlot: name of the column corresponding to the Y variable to plot; string
%         - MkrType, LineType, LineWdth, Clrs, MkrFaceClr: plotting specifications. Clrs is an array where each row is the colour for the ith response type in the RespTypeStr 
%                      cell array, while everything else is a single item common for all the data being plotted (MkrFaceClr can be a string or a 1x3 rgb vector).
function PlotRespEffLena(IpTab,RespTypeStr,X_Offset,YVarToPlot,MkrType,LineType,LineWdth,Clrs,MkrFaceClr)

    LENATab = IpTab(strcmp(IpTab.DataType,'LENA'),:); %filter for LENA daylong data

    PvalVar = regexprep(YVarToPlot,'_.*','P'); %get the p value column for the Y var to plot
    if ~all(LENATab.(PvalVar) < 0.001) %check if there are p values grater than 0.001 (in which case, the code needs to be adapted)
        warning('There are p values greater than 0.001, must adapt code!')
    end

    for i = 1:numel(X_Offset) %this is a one element vector for this plot but keeping the loop for generalisability
        ReqSubTab = LENATab(contains(LENATab.ResponseType,RespTypeStr),:); %filter for response type
        UpperBarVar = regexprep(YVarToPlot,'_.*','CI_Upper'); LwrBarVar = regexprep(YVarToPlot,'_.*','CI_Lwr'); %get upper and lower CI values

        %plot errorbars
        errorbar(ReqSubTab.InfAge_Months+X_Offset(i),ReqSubTab.(YVarToPlot),...
            abs(ReqSubTab.(YVarToPlot) - ReqSubTab.(LwrBarVar)),abs(ReqSubTab.(YVarToPlot) - ReqSubTab.(UpperBarVar)),'Marker',MkrType,'MarkerSize',10,...
            'LineStyle',LineType,'LineWidth',LineWdth,'Color',Clrs(i,:),'MarkerFaceColor',MkrFaceClr);
    end
end


%--------------------------------------------------------------------
% This function takes in the table with results from previous (1 or 2) IEI models and plots the marginal Rsq using plot() and specified plotting styles (for Lday data)
% 
% Inputs: - IpTab: input table
%         - RespTypeStr: string denoting response type (e.g., 'ANRespToCHNSP','CHNSPRespToAN')
%         - X_Offset: offset from the infant age value for plot stagger for data viz. This is avector with the same num of elements as RespTypeStr (and is used to loop through
%                     RespTypeStr)
%         - YVarToPlot: name of the column corresponding to the Y variable to plot; string
%         - MkrType, LineType, LineWdth, Clrs, MkrFaceClr: plotting specifications. Clrs and MkrFaceClr are arrays where each row is the colour for the ith response type 
%                      in the RespTypeStr cell array, while everything else is a single item common for all the data being plotted.
function PlotRsqLena(IpTab,RespTypeStr,X_Offset,YVarToPlot,MkrType,LineType,LineWdth,Clrs,MkrFaceClr)

    LENATab = IpTab(strcmp(IpTab.DataType,'LENA'),:);%filter for LENA daylong data

    for i = 1:numel(X_Offset) %this is a one element vector for this plot but keeping the loop for generalisability
        ReqSubTab = LENATab(contains(LENATab.ResponseType,RespTypeStr),:); %filter for response type
        
        %plot!
        plot(ReqSubTab.InfAge_Months+X_Offset(i),ReqSubTab.(YVarToPlot),'Marker',MkrType,'MarkerSize',10,...
            'LineStyle',LineType,'LineWidth',LineWdth,'Color',Clrs(i,:),'MarkerFaceColor',MkrFaceClr(i,:));
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
function PlotRespEffValData(IpTab,RespTypeStr,DataType,XVec,YVarToPlot,MkrType,LineWdth,Clr,MkrFaceClr)

    ValDataTab = IpTab(strcmp(IpTab.DataType,DataType),:); %filter for data type

    PvalVar = regexprep(YVarToPlot,'_.*','P'); %get the p value column for the Y var to plot
    if ~all(ValDataTab.(PvalVar) < 0.001) %check if there are p values grater than 0.001 (in which case, the code needs to be adapted)
        warning('There are p values greater than 0.001, must adapt code!')
    end

    ReqSubTab = ValDataTab(contains(ValDataTab.ResponseType,RespTypeStr),:); %subset for the response type
    UpperBarVar = regexprep(YVarToPlot,'_.*','CI_Upper'); LwrBarVar = regexprep(YVarToPlot,'_.*','CI_Lwr'); %get upper and lower CI values

    %plot errorbars
    erbr = errorbar(XVec,ReqSubTab.(YVarToPlot),abs(ReqSubTab.(YVarToPlot) - ReqSubTab.(LwrBarVar)),abs(ReqSubTab.(YVarToPlot) - ReqSubTab.(UpperBarVar)), ...
        'Marker',MkrType,'MarkerSize',10,'LineStyle','none','LineWidth',LineWdth,'Color',Clr,'MarkerFaceColor',MkrFaceClr);

    %pvalue signifiers
    posYDelta = erbr.YPositiveDelta; %get y position of positive error bar

    %get significance indicators
    if ReqSubTab.(PvalVar) < 0.001
        SigTxt = '***';
    elseif (ReqSubTab.(PvalVar) >= 0.001) && (ReqSubTab.(PvalVar) < 0.01)
        SigTxt = '**';
    elseif (ReqSubTab.(PvalVar) >= 0.01) && (ReqSubTab.(PvalVar) < 0.05)
        SigTxt = '*';
    elseif ReqSubTab.(PvalVar) >= 0.05
        SigTxt = '';
    end

    text(XVec,posYDelta,SigTxt,'HorizontalAlignment','center','FontSize',28,'FontName','Helvetica Neue','Rotation',90) %add significance indicator

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





