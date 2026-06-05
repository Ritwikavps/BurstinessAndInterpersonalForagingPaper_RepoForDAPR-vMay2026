clearvars; clc

%@author info: code to plot the transformed CurrIVI-PrevIVI regression as well as the WR-WOR residuals in the schematic figure in main text, as well as the more detailed associated 
% SI figs. To do this, we use LENA day-long data where the infant is the vocaliser and the adult is the responder, and pick an infant age randomly and response window = 5s (cuz 
% this is a stable response window and corresponds to LENA conv turns) (for WR-WOR residuals).

%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%CHANGE PATHS AND INPUT STRINGS ACCORDINGLY
Basepath = '~/BaseDataPath/Data/ResultsTabs/ResponseAnalyses/';
cd(Basepath) %go to path with table
Opts = detectImportOptions('TransformedIVIsAndResidsFromPrevIVILmer_AgeBlockLvl_LENA.csv'); %get table import options (this is so we can set columns to the correct data type, eg. string, double, etc)
VarNames = Opts.VariableNames; %Get the variabl names for the table
RespVarNames = VarNames(contains(VarNames,'Response_')); %get the set of response variable names (these need to be set to 'double')
Opts = setvartype(Opts,RespVarNames,'double'); %set the data type for all response columns to double (some of them get read in as strings otherwise)
Opts = setvartype(Opts,'InfantID','string'); %set infant ID data type as string
DataTab = readtable('TransformedIVIsAndResidsFromPrevIVILmer_AgeBlockLvl_LENA.csv',Opts); %Read in data table with the correct options

StatsTab = readtable('AgeLvlPrevIVIBetaAndIntercept_LENA.csv'); %read in table with betas and intercepts
% -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

WOR_Clr = [206 100 99]/256; WR_Clr = [126 167 45]/256; %colours to plot for WR and WOR

%first, randomly select an age for LENA day-long data, infant speaker. 
u_Age = [3 6 9 18]; %get unique ages
RandAgeInd = randi(numel(u_Age)); %pick a random age
ReqTab = DataTab(strcmp(DataTab.ResponseType,'ANRespToCHNSP') & DataTab.AgeMonths == u_Age(RandAgeInd),:); %subset the required table for infant vocs
SubTab_ANVoc = DataTab(strcmp(DataTab.ResponseType,'CHNSPRespToAN') & DataTab.AgeMonths == u_Age(RandAgeInd),:); %subset the required table for adult vocs
    
StatsTab_CHNSPVoc = StatsTab(contains(StatsTab.TypeOfResponse,'ANRespToCHNSP') & StatsTab.InfAge == u_Age(RandAgeInd),:); %pick out info for infant vocs for the randomly chosen age 

%Get response variable
ReqRespVar = 'Response_5'; %pick out the corresponding response variable name

%Get indices to subsample for IVI scatterplot
IVI_inds = 1:numel(ReqTab.CurrIVI);
RandIviInds = randi(max(IVI_inds),1,2000); %subsample 2000 indices

%PLOTTING-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%I) Plot Main text schematic figure (LENA daylong, random age, 5 s response window, infant vocs)

%Get x values for fit (min_prevIVI to max_PrevIVI, with an increment such that there are a total of 201 x points to plot
X_Fit = min(ReqTab.ZscoreLog10_PrevIVI):(range(ReqTab.ZscoreLog10_PrevIVI)/200):max(ReqTab.ZscoreLog10_PrevIVI); 
Lmer_Intercept = StatsTab_CHNSPVoc.Intercept; Lmer_Beta = StatsTab_CHNSPVoc.PrevStBeta; %get betavalue and intercept for plotting from StatsTab 

%compute pieces that go into second subplot: histogram bin centers and frequencies
[WR_Resid_y,WR_Resid_x] = GetHistBinCentersAndVals(ReqTab.ResidualVec(ReqTab.(ReqRespVar) == 1)); %get histogram bin centres and frequencies for WR, for 5s response window
[WOR_Resid_y,WOR_Resid_x] = GetHistBinCentersAndVals(ReqTab.ResidualVec(ReqTab.(ReqRespVar) == 0)); %similarly for WOR

%Initialise figure
figure1 = figure('PaperType','<custom>','PaperSize',[18.5 9],'Color',[1 1 1]);

%subplot 1: transformed CurrIVI vs PrevIVI
axes1 = axes('Parent',figure1,'Position',[0.101733232856066 0.17156862745098 0.362925858053025 0.774673202614379]); hold(axes1,'on'); %get axes
scatter(ReqTab.ZscoreLog10_PrevIVI(RandIviInds),ReqTab.ZscoreLog10_CurrIVI(RandIviInds),30,'filled','Marker','square','MarkerEdgeColor',...
    [0 0.447058826684952 0.74117648601532],'MarkerFaceColor',[0 0.447058826684952 0.74117648601532],'LineWidth',1,'MarkerFaceAlpha',0.5); %scatter plot (data)
plot(X_Fit, X_Fit*Lmer_Beta + Lmer_Intercept, '--','LineWidth',1.5,'Color',[0.603921592235565 0.596078455448151 0.596078455448151]); %line: fit
axis tight; hold(axes1,'off'); set(axes1,'FontSize',24); %set remaining axes properties
xlabel('$f_z  (\mathrm{log}_{10} \: \mathrm{IEI})_{i-1}$','interpreter','latex'); ylabel('$f_z (\mathrm{log}_{10} \mathrm{IEI})_{i}$','Interpreter','latex');
title('C')


%subplot 2: WR and WOR residuals
axes2 = axes('Parent',figure1,'Position',[0.581644601630472 0.172058823529412 0.362925858053025 0.774673202614379]); hold(axes2,'on');
plot(WR_Resid_x,WR_Resid_y,'Marker','s','LineWidth',1.5,'Color',[WR_Clr 0.5],'MarkerSize',6,'MarkerFaceColor','auto'); %plot WR
plot(WOR_Resid_x,WOR_Resid_y,'Marker','none','LineWidth',1.5,'Color',[WOR_Clr 0.8],'MarkerSize',20); %plot WOR
%plot(WR_Resid_x,WR_Resid_y,'LineWidth',1.5,'Color',[WR_Clr 0.2]);
%plot(WOR_Resid_x,WOR_Resid_y,'LineWidth',1.5,'Color',[WOR_Clr 0.2]);
axis tight; hold(axes2,'off'); set(axes2,'FontSize',24);
title('D'); legend('with response (Resp)','w/o response (NoResp)'); xlabel('Residual IEIs'); ylabel('Frequency (normalized)'); 

% Create textbox
annotation(figure1,'textbox',[0.832289491997218 0.0394074706124531 0.0410427247474155 0.0699490658900936],'String',{'($R$)'},'Interpreter','latex',...
    'FontSize',26,'FontName','Helvetica Neue','EdgeColor','none');
annotation(figure1,'textbox',[0.00396825396825397 0.965049382716049 0.19212962962963 0.0277777777777778],...
        'String',strcat('Infant age = ',num2str(u_Age(RandAgeInd)),' months; infant vocaliser; response window = 5 s')); %textbox


%-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%II) Plot extra SI fig: raw and transformed curr IVI vs Prev IVI plots
figure1 = figure('PaperType','<custom>','PaperSize',[19.25 9.5],'Color',[1 1 1]);

%Subplot 1: raw curr IVI vs prev IVI scatter.
axes1 = axes('Parent',figure1,'Position',[0.0884833627007842 0.148588410104012 0.382902058678403 0.805349182763744]); hold(axes1,'on');
scatter(ReqTab.PrevIVI(RandIviInds),ReqTab.CurrIVI(RandIviInds),30,'MarkerEdgeAlpha',0.7,'MarkerEdgeColor',[0 0.447058826684952 0.74117648601532],...
    'LineWidth',1,'MarkerFaceAlpha',0.3,'MarkerFaceColor',[0 0.447058826684952 0.74117648601532],'Marker','square');
title('A'); ylabel('(raw; s)'); xlabel(' (raw; s)'); 
axis(axes1,'tight'); hold(axes1,'off'); set(axes1,'FontSize',24);


% subplot 2: transformed curr IVI vs prev IVI scatter + fit
axes2 = axes('Parent',figure1,'Position',[0.587719298245613 0.148588410104012 0.406084656084657 0.806661159603389]); hold(axes2,'on');
scatter(ReqTab.ZscoreLog10_PrevIVI(RandIviInds),ReqTab.ZscoreLog10_CurrIVI(RandIviInds),30,'MarkerEdgeAlpha',0.5, ...
    'MarkerEdgeColor',[0 0.447058826684952 0.74117648601532],'LineWidth',1,'MarkerFaceAlpha',0.3,'MarkerFaceColor',[0 0.447058826684952 0.74117648601532],'Marker','square');
plot(X_Fit, X_Fit*Lmer_Beta + Lmer_Intercept,'LineWidth',1.5,'LineStyle','--','Color',[0.603921592235565 0.596078455448151 0.596078455448151]);
title('B'); ylabel('$f_z ({\rm log}_{10} {\rm IEI})_{i}$','Interpreter','latex'); xlabel('$f_z ({\rm log}_{10} {\rm IEI})_{i-1}$','Interpreter','latex');
axis(axes2,'tight'); hold(axes2,'off'); set(axes2,'FontSize',24);

%Annotations
annotation(figure1,'textbox',[0.247424115845167 0.00149586920983211 0.0363756613756613 0.0496323529411766],'String',{'${\rm IEI}_{i-1}$'},...
'LineStyle','none','Interpreter','latex','FontSize',26,'FontName','Helvetica Neue','FitBoxToText','off'); %textbox
annotation(figure1,'line',[0.0417710944026716 0.865845168476742],[0.987770113669066 0.987770113669066]); %line
annotation(figure1,'textbox',[0.0281606794764689 0.445126850397206 0.0516481009143138 0.0576523034037665],'String',{'${\rm IEI}_i$'},'Rotation',90,...
'Interpreter','latex','FontSize',24,'FontName','Helvetica Neue','EdgeColor','none'); %textbox
annotation(figure1,'line',[0.0876496797549387 0.0876496797549387],[0.940790806522636 0.132364577014437]); %line

%-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%III) Plot extra SI fig: raw and transformed IVI dists + residual dists (WR and WOR)

%compute pieces that go into subplots 3 and 4: WR and WOR distributions for raw IVI and transformed IVI for 5 s response window
[WR_IVI_y,WR_IVI_x] = GetHistBinCentersAndVals(ReqTab.CurrIVI(ReqTab.(ReqRespVar) == 1)); %Raw IVI
[WOR_IVI_y,WOR_IVI_x] = GetHistBinCentersAndVals(ReqTab.CurrIVI(ReqTab.(ReqRespVar) == 0));

[WR_IVItrans_y,WR_IVItrans_x] = GetHistBinCentersAndVals(ReqTab.ZscoreLog10_CurrIVI(ReqTab.(ReqRespVar) == 1)); %Transformed IVI
[WOR_IVItrans_y,WOR_IVItrans_x] = GetHistBinCentersAndVals(ReqTab.ZscoreLog10_CurrIVI(ReqTab.(ReqRespVar) == 0)); 


figure1 = figure('PaperType','<custom>','PaperSize',[21.5 11.5],'Color',[1 1 1]);

%subplot 1: raw IVI distributions (WR/WOR)
axes1 = axes('Parent',figure1,'Position',[0.0833333333333332 0.102850061957869 0.40542328042328 0.879801734820322]); hold(axes1,'on');
plot(WR_IVI_x,WR_IVI_y,'MarkerFaceColor','auto','MarkerSize',9,'Marker','square','LineWidth',1,'Color',WR_Clr);
plot(WOR_IVI_x,WOR_IVI_y,'LineWidth',2,'Color',WOR_Clr);
title('A'); xlabel('IEI (raw; s)'); ylabel('Frequency (normalized)'); hold(axes1,'off');
set(axes1,'FontSize',24,'XLimitMethod','tight','YLimitMethod','tight','ZLimitMethod','tight');
legend({'with response (Resp)','w/o response (NoResp)'},'Position',[0.405423280423279 0.905204441319495 0.0787037037037036 0.0700123915737298]);

% subplot 2: transformed IVI distributions (WR/WOR)
axes3 = axes('Parent',figure1,'Position',[0.578042328042328 0.619578686493185 0.402777777777773 0.363073110285006]); hold(axes3,'on');
plot(WR_IVItrans_x,WR_IVItrans_y,'MarkerFaceColor','auto','MarkerSize',5,'Marker','square','LineWidth',1.5,'Color',WR_Clr);
plot(WOR_IVItrans_x,WOR_IVItrans_y,'LineWidth',1.5,'Color',WOR_Clr);
title('B'); xlabel('$f_z ({\rm log}_{10} {\rm IEI}) $ ','Interpreter','latex'); hold(axes3,'off');
set(axes3,'FontSize',24,'XLimitMethod','tight','YLimitMethod','tight','ZLimitMethod','tight');
legend({'Resp','NoResp'},'Position',[0.801917976846749 0.905204456497308 0.174272486772487 0.0700123915737298]);

% subplot 3: residuals (WR/WOR)
axes2 = axes('Parent',figure1,'Position',[0.578042328042328 0.10353828827209 0.402777777777774 0.35742825447884]); hold(axes2,'on');
plot(WR_Resid_x,WR_Resid_y,'MarkerFaceColor','auto','MarkerEdgeColor',WR_Clr,'MarkerSize',5,'Marker','square','LineWidth',1.5,'Color',WR_Clr);
plot(WOR_Resid_x,WOR_Resid_y,'LineWidth',1.5,'Color',WOR_Clr);
title('C'); xlabel('Residual IEIs'); 
hold(axes2,'off'); set(axes2,'FontSize',24,'XLimitMethod','tight','YLimitMethod','tight','ZLimitMethod','tight');
legend({'Resp','NoResp'},'Position',[0.832010569439341 0.383519202538687 0.144179894179894 0.0700123915737298]);
%-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%Plot Infant vocaliserm by age WR and WOR residuals
AxesPos = [0.10339593114241 0.572311495673671 0.394827856025041 0.393479604449935;
           0.589201877934272 0.572311495673671 0.394827856025041 0.393479604449935;
           0.10339593114241 0.103819530284302 0.394827856025041 0.393479604449935;
           0.589201877934272 0.103819530284302 0.394827856025041 0.393479604449935];

ANVoc_Xlim = [-2 6.2]; ANVoc_Ylim =[-0.001 0.071];
CHNSPVoc_Xlim = [-2 6]; CHNSPVoc_Ylim =[-0.002 0.06];
GetByAgeRespNoRespResidualPlots(DataTab,'ANRespToCHNSP',u_Age,AxesPos,WR_Clr, WOR_Clr,ReqRespVar,CHNSPVoc_Xlim,CHNSPVoc_Ylim)
GetByAgeRespNoRespResidualPlots(DataTab,'CHNSPRespToAN',u_Age,AxesPos,WR_Clr, WOR_Clr,ReqRespVar,ANVoc_Xlim,ANVoc_Ylim)

%FINALLY, print outputs to console
fprintf('Data used: LENA day-long, CHNSP vocaliser, infant age = %i months, response window = %0.1f s \n',u_Age(RandAgeInd),...
                                                                          str2double(regexprep(ReqRespVar,'.*_',''))) %details of recording
fprintf('The linear fit for log-d, z-scored CurrIEI vs. PrevIEI is %0.4f x + %0.4e\n',Lmer_Beta,Lmer_Intercept) %linear fit values and p value of slope


%--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%This function computes the histogram bin centres and frequencies of the input variable (WR and WOR resiuals/IVIs, as applicable).
function [BinFreq,BinCenterVals] = GetHistBinCentersAndVals(TargetVar)
    NumBins = GetNumBinsFDRule(TargetVar); %get number pf bins
    [BinFreq,BinEdges] = histcounts(TargetVar,NumBins,'Normalization','probability'); %get histogram bin edges and frequencies. Numbins set by Friedman Diaconis rule
    %Setting num bins to 12 is based on the Friedman Diaconis rule for the randomly chosen recording that is shown in the paper draft. Can adapt this to properly depend on the
    % currently randomly selected data instead.
    BinCenterVals = 0.5*(BinEdges(1:end-1)+BinEdges(2:end)); %get bin centers
end

%-------------------------------------------------------------------------------------
%This function gets the number of bins for histogram given a vector with values to be binned using the Friedman Diaconis rule. The FD rule is derived using a normal distribution
% assumption, and since the residuals and the transformed IVIs are reasonably normal (visually, at least), this is fair use. Per the FD rule, the bin width = 2 * iqr(data)/n^1/3.
% Here, n is the number of elements in the vector.
function NumBins = GetNumBinsFDRule(Xvec)
    BinWidth = 2*iqr(Xvec)/((numel(Xvec))^(1/3));
    NumBins = round(range(Xvec)/BinWidth);
end


%-------------------------------------------------------------------------------------
%This function takes the data table (DataTab), a string specifying response/vocalisaer combo (RespAndVocStr), and the vector of unique infant ages (u_Age), and plots Resp and 
% NoResp residual histograms (bin numbers according to Freidman Diaconis rule) for each infant age as a subplot. Other inputs are an array with positions for each subplot with ith 
% subplot position as the ith row (AxesPos), and colours for Resp and NoResp plots (WR_Clr and WOR_Clr, respectively), the repsonse variable name corresponding to teh desired 
% response window, and the X and Y limits (Xlim, Ylim).
function [] = GetByAgeRespNoRespResidualPlots(DataTab,RespAndVocStr,u_Age,AxesPos,WR_Clr, WOR_Clr,ReqRespVar, Xlim, Ylim)
    %Initialise fig
    figure1 = figure('PaperType','<custom>','PaperSize',[18.5 11.5],'Color',[1 1 1]); 
    
    %go through ages to subset
    for i = 1:numel(u_Age)
        ReqTab = DataTab(strcmp(DataTab.ResponseType,RespAndVocStr) & DataTab.AgeMonths == u_Age(i),:); %subset data table for response/vocaliser combo and infant age
        [WR_Resid_y,WR_Resid_x] = GetHistBinCentersAndVals(ReqTab.ResidualVec(ReqTab.(ReqRespVar) == 1)); %get histogram bin centres and frequencies for WR, for 5 s response window
        [WOR_Resid_y,WOR_Resid_x] = GetHistBinCentersAndVals(ReqTab.ResidualVec(ReqTab.(ReqRespVar) == 0)); %similarly for WOR
        
        axes1 = axes('Parent',figure1,'Position',AxesPos(i,:)); hold(axes1,'on');
        plot(WR_Resid_x,WR_Resid_y,'MarkerFaceColor','auto','MarkerSize',5,'Marker','square','LineWidth',1.5,'Color',WR_Clr);
        plot(WOR_Resid_x,WOR_Resid_y,'LineWidth',1.5,'Color',WOR_Clr);
        %histogram(SubTab_CHNSPVoc.ResidualVec(SubTab_CHNSPVoc.(ReqRespVar) == 1),'Normalization','probability')
        %histogram(SubTab_CHNSPVoc.ResidualVec(SubTab_CHNSPVoc.(ReqRespVar) == 0),'Normalization','probability')
        title(num2str(u_Age(i))); 
        
        %set conditions for legend, axis labels
        if i == 1
            legend({'Resp','NoResp'})
        end
        if ismember(i,[1 3])
            ylabel('Frequency (normalized)');
        end
        if ismember(i,[3 4])
            xlabel('Residual IEIs');
        end
    
        xlim(axes1,Xlim); ylim(axes1,Ylim); hold(axes1,'off');
        set(axes1,'FontName','Helvetica Neue','FontSize',24);
    end

    annotation(figure1,'textbox',[0.00396825396825397 0.965049382716049 0.19212962962963 0.0277777777777778],...
        'String',strcat('5 s; ',RespAndVocStr)); %textbox
end
% %-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
% %III) A thought for a set of IS plots is this: an 8 panel figure with C and D from the SI fig associated with Fig 1 in main text, repeated 4 times for each data type (LENA day-long, LENA 
% 5 min, human listener labelled 5 min with all adult vocs, and human listener labelled 5 min with only infant directed adult vocs). One figure would have this for CHNSP utterances, and 
% a second figure would have this for adult utterances. Because we are demo-ing WR and WOR, we'd have to pick a response window. While these figure would look nice, they don't add any more 
% info than the analyses, and the analyses show the (possible) conclusions from these figures in more statistically grounded and elegant ways. Below, some preliminary code for these proposed 
% figures are provided (commented out).
% figure;
% 
% %CHNSP utterances: LENA day long
% %Get distributions for CHNSP utterances, 2 s response window, LENA daylong data
% ReqTab = DataTab(strcmp(DataTab.DataType,'LENA') & strcmp(DataTab.ResponseType,'ANRespToCHNSP'),:); %subset the required table
% 
% %Raw IVI distributions
% [WR_IVI_y,WR_IVI_x] = GetHistBinCentersAndVals(ReqTab.CurrIVI(ReqTab.Response_2 == 1)); %Raw IVI
% [WOR_IVI_y,WOR_IVI_x] = GetHistBinCentersAndVals(ReqTab.CurrIVI(ReqTab.Response_2 == 0));
% 
% %Transformed IVI distributions
% [WR_IVItrans_y,WR_IVItrans_x] = GetHistBinCentersAndVals(ReqTab.CurrIVI_Trans(ReqTab.Response_2 == 1)); %Transformed IVI
% [WOR_IVItrans_y,WOR_IVItrans_x] = GetHistBinCentersAndVals(ReqTab.CurrIVI_Trans(ReqTab.Response_2 == 0)); 
% 
% %Residual distributions
% [WR_Resid_y,WR_Resid_x] = GetHistBinCentersAndVals(ReqTab.ResidVar(ReqTab.Response_2 == 1)); %get histogram bin centres and frequencies for WR, for randomly chosen response window
% [WOR_Resid_y,WOR_Resid_x] = GetHistBinCentersAndVals(ReqTab.ResidVar(ReqTab.Response_2 == 0)); %similarly for WOR
% 
% 
% subplot(4,2,1);
% hold all
% plot(WR_IVI_x,WR_IVI_y,'LineWidth',1,'Color',WR_Clr,'.');
% plot(WOR_IVI_x,WOR_IVI_y,'LineWidth',1,'Color',WOR_Clr,'.');
% 
% subplot(4,2,2);
% hold all
% plot(WR_IVItrans,WR_IVItrans_y,'LineWidth',1,'Color',WR_Clr,'.');
% plot(WOR_IVItrans_x,WOR_IVItrans_y,'LineWidth',1,'Color',WOR_Clr,'.');
% plot(WR_Resid,WR_Resid_y,'LineWidth',1,'Color',WR_Clr,'+');
% plot(WOR_Resid_x,WOR_Resid_y,'LineWidth',1,'Color',WOR_Clr,'+');
% 
% 
% %CHNSP utterances: LENA 5 min
% 
% %CHNSP utterances: H 5 min, all adult
% 
% %CHNSP utterances: H 5 min, chnsp-directed  adult



