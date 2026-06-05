clear; clc

%@author info
%This script computes the number of yes, no, and NA responses (NA voctype onset within response window OR IEI less than repsonse window), for each response window, for CHNSP and AN vocs,
% and expresses the percent of total IEIs excluded as a result of NA response thresholds.

%set base path
BasePath = '~/BaseDataPath/Data/ResultsTabs/ResponseAnalyses/';

StrForPaths = {'LENA','LENA5min','H','H_ChildDirANOnly'}; %the strings for paths to the files
StrForFiles = {'LENA','LENA5min','Hum','ChildDirANOnly_Hum'}; %the strings to read in files
ResponseType = {'_ANRespToCHNSP_','_CHNSPRespToAN_'};

Resps = [0.5 1:10]; %response windows
RespVars{1} ='Response_0_5'; %get response variable name in table for 0.5 s response window (cuz this is how MATLAB reads it in)
for i = 2:numel(Resps) %get the rest of response window variable names
    RespVars{i} = strcat('Response_',num2str(Resps(i)));
end

%go through the different paths, read in files, get numbers, etc. 
for i = 1:numel(StrForPaths) %i indexes the data type
    CurrPath = strcat(BasePath,'ResponseEffect_w_CurrPrevStSizeControl_',StrForPaths{i},'/'); %get current path
    cd(CurrPath) %go to ucrrent path

    for j = 1:numel(ResponseType) % go through response types 9indexed by j)
        CurrFileName = strcat('CurrPrevStSize_',StrForFiles{i},ResponseType{j},'IviOnly.csv'); %get file names
        CurrTab = readtable(CurrFileName); %read file

        NumIVIs(i,j) = numel(CurrTab.CurrIVI); %get number of IVIs for that combo of data type and response type
        for k = 1:numel(RespVars) %go through response windows (indexed by k)
            CurrRespVar = CurrTab.(RespVars{k}); %read in response variable
            Num_Y_Resp{i,j}(k,1) = numel(CurrRespVar(CurrRespVar == 1)); %number of yes responses
            Num_N_Resp{i,j}(k,1) = numel(CurrRespVar(CurrRespVar == 0)); %no responses
            Num_NA_Resp{i,j}(k,1) = numel(CurrRespVar(isnan(CurrRespVar))); %NA responses
        end
    end
end

%Check that the total number of infant IVIs for human labelled data with all adult vocs and only infant directed adulty vocs are the same. Note that this won't be the same for Yes, no,
% or NA responses. While it is evident why yes and no response numbers should differ (because it is based on adult responses), it is not as obvious as to why the number of NA responses
% won't remain the same. This is because NA responses are assessed if there is a CHNSP or CHNNSP utterance within T_resp of the current CHNSP utterance OR if the CHNSP-CHNSP IVI is less
% than T_resp. So, for H (All Ad) vs H(T Ad), there can be a situation where there is CHNSP, AN, CHNNSP where the AN and CHNNSP are within T_resp of the first CHNSP. If this AN is not
% a T adult utterance, it will be excluded for H (T Ad), which will results in the sequence CHNSP, CHNNSP. This way, the first sequence will result in a Y resp while the second will 
% result in NA.
if NumIVIs(3,1) ~= NumIVIs(4,1)
    error('Number of IVIs should be the same for CHNSP All Ad and T Ad datasets (because the number of CHNSP vocs do not change')
end


%---------------------------------------------------------------
%Plotting: Total number of IVIs, validation data
figure1 = figure('PaperType','<custom>','PaperSize',[10 9.5],'Color',[1 1 1]);
axes1 = axes('Parent',figure1,'Position',[0.16862660944206 0.134767801857585 0.775 0.815]); hold(axes1,'on');
bar1 = bar(NumIVIs(2:end,:)');
for i = 1:numel(bar1)
    bar1(i).Labels = bar1(i).YData;
end
set(bar1(1),'DisplayName','L (5min)','FaceColor',[0.92156862745098 0.815686274509804 0.149019607843137],'EdgeColor','none');
set(bar1(2),'DisplayName','H (5min; All Ad)','FaceColor',[0.184313725490196 0.309803921568627 0.56078431372549],'EdgeColor','none');
set(bar1(3),'DisplayName','H (5min; T-Ad)','FaceColor',[0.290196078431373 0.6 0.180392156862745],'EdgeColor','none');
ylabel({'Total number of IEIs'}); xlabel({'Segment label'});
ylim(axes1,[0 25000]); hold(axes1,'off');
set(axes1,'FontSize',24,'XLimitMethod','tight','XTick',[1 2],'XTickLabel',{'ChSp','Ad'},'YLimitMethod','tight','ZLimitMethod','tight');
legend(axes1,'show');


%---------------------------------------------------------------
%Plotting: LENA day-long data + total IEI numbers.
figure1 = figure('PaperType','<custom>','PaperSize',[21.5 9.75],'Color',[1 1 1]);

DataTypeInd = 1; %LENA day-long: indices: 1 (for LENA data)

%bar plot showing total CHNSP and AN IVIs
axes3 = axes('Parent',figure1,'Position',[0.0625396825396823 0.179698216735254 0.132566137566138 0.727469135802467]); hold(axes3,'on');
b1 = bar(NumIVIs(DataTypeInd,:),'FaceColor',[0.341176470588235 0.341176470588235 0.341176470588235]);
b1(1).Labels = b1(1).YData;
ylabel('Total number of IEIs'); xlabel('Segment label'); title('A');
ylim(axes3,[0 450000]); hold(axes3,'off');
set(axes3,'FontSize',24,'XLimitMethod','tight','XTick',[1 2],'XTickLabel',{'ChSp','Ad'},'YLimitMethod','tight','YMinorTick','on','YTick',...
    [0 100000 200000 300000 400000],'ZLimitMethod','tight');


%number of Y, N and NA responses as a function or response window
RespInd = 1; %Plot: AN Resp to CHNSP; index: 1 (for AN resp to CHNSP). These are CHNSP vocalisers.

axes1 = axes('Parent',figure1,'Position',[0.310760104729173 0.179698216735254 0.329201440026174 0.727469135802467]); hold(axes1,'on');
title('B');
TxtBoxTxt = GetLdayPlots(axes1,Resps,Num_Y_Resp,Num_N_Resp,Num_NA_Resp,NumIVIs,DataTypeInd,RespInd,StrForPaths,ResponseType,'-'); %see user defined function below
legend({'Y response','N response','NA response'},'Position',[0.248731787721686 0.777777777777777 0.21031746031746 0.077503429355281]);
annotation(figure1,'textbox',[0.00132275132275129 0.00105761316872205 0.0909391534391534 0.0308641975308642],'String',TxtBoxTxt);


RespInd = 2; %Plot: CHNSP Resp to AN; index: 2 (for CHNSP resp to AN). These are AN vocalisers.

axes2 = axes('Parent',figure1,'Position',[0.665998472699496,0.179698216735253,0.329201440026174,0.727469135802466]); hold(axes2,'on');
title('C');
TxtBoxTxt = GetLdayPlots(axes2,Resps,Num_Y_Resp,Num_N_Resp,Num_NA_Resp,NumIVIs,DataTypeInd,RespInd,StrForPaths,ResponseType,'-');
annotation(figure1,'textbox',[0.916005291005289 0.00168587105624242 0.0909391534391534 0.0308641975308642],'String',TxtBoxTxt);


%---------------------------------------------------------------
%Plotting: Validation data
figure1 = figure('PaperType','<custom>','PaperSize',[21.5 9.75],'Color',[1 1 1]);

%colours for each validation
Clrs = [0 0.447058823529412 0.741176470588235
    0.850980392156863 0.325490196078431 0.0980392156862745
    0.901960784313726 0.650980392156863 0.0705882352941176];


RespInd = 1; %Plot: AN Resp to CHNSP; index: 1 (for AN resp to CHNSP). These are CHNSP vocalisers.

axes1 = axes('Parent',figure1,'Position',[0.0865537555228276 0.162128712871287 0.388070692194403 0.652216857488216]); hold(axes1,'on');
title('A');

DataTypeInd = 2; %LENA 5 min data: index = 2 
GetValDataPlots(axes1,Resps,Num_Y_Resp,Num_N_Resp,Num_NA_Resp,NumIVIs,DataTypeInd,RespInd,ResponseType,'-','hexagram',10,1.5,Clrs);

DataTypeInd = 3; %human labelled data, all adult vocs included
GetValDataPlots(axes1,Resps,Num_Y_Resp,Num_N_Resp,Num_NA_Resp,NumIVIs,DataTypeInd,RespInd,ResponseType,':','diamond',10,2,Clrs);

DataTypeInd = 4; %human labelled data, child directed adult vocs ONLY
TxtBoxTxt = GetValDataPlots(axes1,Resps,Num_Y_Resp,Num_N_Resp,Num_NA_Resp,NumIVIs,DataTypeInd,RespInd,ResponseType,'--','.',14,1.5,Clrs);

hold(axes1,'off');
set(axes1,'FontName','Helvetica Neue','FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorGrid','on','XMinorTick','on','XTick',[0.5 2 4 6 8 10],...
    'YGrid','on','YLimitMethod','tight','YMinorGrid','on','YMinorTick','on','YScale','log','YTick',[0.02 0.05 0.1 0.25 0.5 1],'ZLimitMethod','tight');
legend({'Y response, L (5min)','N response, L (5min)','NA response, L (5min)', ...
    'Y response, H (5min; All Ad)','N response, H (5min; All Ad)','NA response, H (5min; All Ad)',...
    'Y response, H (5min; T-Ad)','N response, H (5min; T-Ad)','NA response, H (5min; T-Ad)'},...
    'Position',[0.263410596026491 0.849625184723082 0.595033112582781 0.135687732342007],'NumColumns',3)
annotation(figure1,'textbox',[0.00132275132275129 0.00105761316872205 0.0909391534391534 0.0308641975308642],'String',TxtBoxTxt);


RespInd = 2; %Plot: CHNSP Resp to AN; index: 2 (for CHNSP resp to AN). These are AN vocalisers.

axes2 = axes('Parent',figure1,'Position',[0.603829160530191 0.162128712871287 0.388070692194403 0.652216857488216]); hold(axes2,'on');
title('B');

DataTypeInd = 2; %LENA 5 min data: index = 2 
GetValDataPlots(axes2,Resps,Num_Y_Resp,Num_N_Resp,Num_NA_Resp,NumIVIs,DataTypeInd,RespInd,ResponseType,'-','hexagram',10,1.5,Clrs);

DataTypeInd = 3; %human labelled data, all adult vocs included
GetValDataPlots(axes2,Resps,Num_Y_Resp,Num_N_Resp,Num_NA_Resp,NumIVIs,DataTypeInd,RespInd,ResponseType,':','diamond',10,2,Clrs);

DataTypeInd = 4; %human labelled data, child directed adult vocs ONLY
TxtBoxTxt = GetValDataPlots(axes2,Resps,Num_Y_Resp,Num_N_Resp,Num_NA_Resp,NumIVIs,DataTypeInd,RespInd,ResponseType,'--','.',14,1.5,Clrs);

hold(axes2,'off');
set(axes2,'FontName','Helvetica Neue','FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorGrid','on','XMinorTick','on','XTick',[0.5 2 4 6 8 10],...
    'YGrid','on','YLimitMethod','tight','YMinorGrid','on','YMinorTick','on','YScale','log','YTick',[0.02 0.05 0.1 0.25 0.5 1],'ZLimitMethod','tight');
annotation(figure1,'textbox',[0.916005291005289 0.00168587105624242 0.0909391534391534 0.0308641975308642],'String',TxtBoxTxt);


%------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%FUNCTIONS USED
%------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%This function plots subplots with fraction of Y, N, and NA responses (as fraction of total IVIs) for lena daylong data and returns a string to add to a text box to ID the kind of 
% data that is being plotted. Each subplot is for a responder and vocaliser combo.
% 
% Inputs: Axes: axis handle to plot in
%         Resps: response window vector for x axis
%         Num_Y_Resp, Num_NA_Resp, NumIVIs: cell arrays w/ vectors of number of each response types as a function of response window. Indexed by data type and responde type (see below)
%         DataTypeInd, RespInd: indices to index Num_Y_Resp etc by datatype and response type
%         StrForPaths: cell array with strings for paths (specifying data types); indexed by DataTypeInd
%         ResponseType: cell array with response type; indexed by RespInd
%         LineType: the type of line for this plot.
% 
% Output: TxtBoxTxt: string to add to a text box to ID the kind of data that is being plotted.
function [TxtBoxTxt] = GetLdayPlots(Axes,Resps,Num_Y_Resp,Num_N_Resp,Num_NA_Resp,NumIVIs,DataTypeInd,RespInd,StrForPaths,ResponseType,LineType)
    
    %plot fractions of each response type
    plot(Resps,Num_Y_Resp{DataTypeInd,RespInd}/NumIVIs(DataTypeInd,RespInd),'MarkerSize',18,'Marker','.','LineWidth',1,'LineStyle',LineType);
    plot(Resps,Num_N_Resp{DataTypeInd,RespInd}/NumIVIs(DataTypeInd,RespInd),'MarkerSize',18,'Marker','.','LineWidth',1,'LineStyle',LineType);
    plot(Resps,Num_NA_Resp{DataTypeInd,RespInd}/NumIVIs(DataTypeInd,RespInd),'MarkerSize',18,'Marker','.','LineWidth',1,'LineStyle',LineType);
    ylabel('Fraction of IEIs'); xlabel('Response window, T_{resp} (s)'); 
    xlim(Axes,[0.2 10.2]); ylim(Axes,[0 1]); hold(Axes,'off');
    set(Axes,'FontName','Helvetica Neue','FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorGrid','on','XMinorTick','on','XTick',[0.5 2 4 6 8 10],...
    'YGrid','on','YLimitMethod','tight','YMinorGrid','on','YMinorTick','on','YTick',[0 0.2 0.4 0.6 0.8 1],'ZLimitMethod','tight');
    
    TxtBoxTxt = strcat(StrForPaths{DataTypeInd},ResponseType{RespInd}); %get the text box string
end

%----------------------------------------------------------
%This function plots subplots with fraction of Y, N, and NA responses (as fraction of total IVIs) for validation data and returns a string to add to a text box to ID the kind of 
% data that is being plotted.  Each subplot is for a responder and vocaliser combo.
% 
% Inputs: Axes: axis handle to plot in
%         Resps: response window vector for x axis
%         Num_Y_Resp, Num_NA_Resp, NumIVIs: cell arrays w/ vectors of number of each response types as a function of response window. Indexed by data type and responde type (see below)
%         DataTypeInd, RespInd: indices to index Num_Y_Resp etc by datatype and response type
%         ResponseType: cell array with response type; indexed by RespInd
%         LineType: the type of line for this plot
%         MkrType, MkrSz: marker type and size
%         LineWdth: line width
%         Clrs: colours Y, N, and NA responses, in that order.
% 
% Output: TxtBoxTxt: string to add to a text box to ID the kind of data that is being plotted.
function [TxtBoxTxt] = GetValDataPlots(Axes,Resps,Num_Y_Resp,Num_N_Resp,Num_NA_Resp,NumIVIs,DataTypeInd,RespInd,ResponseType,...
                    LineType,MkrType,MkrSz,LineWdth,Clrs)
    
    plot(Resps,Num_Y_Resp{DataTypeInd,RespInd}/NumIVIs(DataTypeInd,RespInd),'Marker',MkrType,'LineWidth',LineWdth,'Color',Clrs(1,:),'LineStyle',LineType,MarkerSize=MkrSz);
    plot(Resps,Num_N_Resp{DataTypeInd,RespInd}/NumIVIs(DataTypeInd,RespInd),'Marker',MkrType,'LineWidth',LineWdth,'Color',Clrs(2,:),'LineStyle',LineType,MarkerSize=MkrSz);
    plot(Resps,Num_NA_Resp{DataTypeInd,RespInd}/NumIVIs(DataTypeInd,RespInd),'Marker',MkrType,'LineWidth',LineWdth,'Color',Clrs(3,:),'LineStyle',LineType,MarkerSize=MkrSz);
    ylabel('Fraction of IEIs'); xlabel('Response window, T_{resp} (s)'); 
    xlim(Axes,[0.2 10.2]); ylim(Axes,[0.02 1]); 
    
    TxtBoxTxt = strcat(ResponseType{RespInd});
end