clear; clc

%Ritwika VPS, Jan 2025
% This script takes the recording day level burstiness measure tables and plots box plots summarising burstiness measures for the LENA daylong data (separated by age
% block; 3, 6, 9, and 18 months) and the validation data (not separated by age block), for CHNSP and AN vocs.
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%PLEASE CHANGE PATHS AND STRINGS IN FUNCTION CALL APPROPRIATELY
DataPath = '~/Desktop/GoogleDriveFiles/research/IVFCRAndOtherWorkWithAnne/Pre_registration_followu/Data/ResultsTabs/DataDescriptionSummaries/';
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
cd(DataPath)

%data type strings and speaker types for burstiness table 
ValDataType = {'L5min','H5min','H5min_T_Ad'};
ValDataType_Xlabels = {'L (5min)','H (5min; All Ad)','H (5min; T-Ad)'};
%ValDataTypeList = {'LENA5min','Hum-AllAd','HumChildDirAdOnly'}; %for x axis labels
SpkrType_Burstiness = {'CHNSP','AN'}; %to pull from table

u_Ages = [3 6 9 18]'; %ages in months

Ctr = 0; %Initialise counter variable


%% Plotting
figure1 = figure('PaperType','<custom>','PaperSize',[18 8.5],'Color',[1 1 1]);

%--LENA daylong data--------------------------------------------------------------------------------------------------------
axes1 = axes('Parent',figure1,'Position',[0.161084656084655 0.159375 0.3639947089947 0.788194444444444]); hold(axes1,'on');
%Get rec level burstiness table (read in the correct sheet for the current data ty[e).
opts = detectImportOptions('RecLvlBurstinessMeasure.xlsx','Sheet','Lday'); %opts makes sure that we are reading in the correct sheet
opts.SelectedVariableNames = {'BurstinessQt','SpeakerType','InfantAgeMonths','NumIeis'};
BurstinessTab_Lday = readtable('RecLvlBurstinessMeasure.xlsx',opts);
BurstinessTab_Lday = BurstinessTab_Lday(contains(BurstinessTab_Lday.SpeakerType,{'AN','CHNSP'}) & ... %filter speaker types and ages
                                                        ismember(BurstinessTab_Lday.InfantAgeMonths,u_Ages),:);
b = boxchart(BurstinessTab_Lday.InfantAgeMonths,BurstinessTab_Lday.BurstinessQt,'GroupByColor',categorical(BurstinessTab_Lday.SpeakerType,{'CHNSP','AN'}), ...
    'Notch','on','MarkerStyle','.','MarkerSize',8,'BoxWidth',0.7,'BoxFaceAlpha',0.5); %box chart
%The categorical(BurstinessTab_Lday.SpeakerType,{'CHNSP','AN'}) is used to preserve the order such that CHNSP is first, so that the legend is correct.
b(1).BoxFaceColor = [0 0.4470 0.7410]; b(1).MarkerColor = [0 0.4470 0.7410]; b(2).BoxFaceColor = [0 0 0]; b(2).MarkerColor = [0 0 0]; %set colours
plot(2:19,zeros(size(2:19)),':','LineWidth',2,'Color',[0.7 0.7 0.7]) %0 line
legend({'ChSp','Ad'},'Position',[0.166005291005291 0.170746527777778 0.0631613756613756 0.0980902777777778]); %legend
axis tight; ylim(axes1,[-1 1]); box(axes1,'on'); 
xlabel('Infant age (months)'); ylabel('Burstiness measure'); title('A') %titles etc
hold(axes1,'off');
set(axes1,'FontSize',24,'XGrid','on','XTick',[3 6 9 18],'YGrid','on','YMinorGrid','on','YMinorTick','on');


%--Validation data--------------------------------------------------------------------------------------------------------
axes2 = axes('Parent',figure1,'Position',[0.546957671957666 0.159375 0.363994708994701 0.788194444444445]); hold(axes2,'on');
BurstinessTab_Valdata = table(); ValDataTypeCol_Str = []; ValDataTypeCol_Code = []; %Initialise tables etc to store data
for i = 1:numel(ValDataType) %We need to load each validation data type from its own excel sheet
    opts = detectImportOptions('RecLvlBurstinessMeasure.xlsx','Sheet',ValDataType{i}); %opts makes sure that we are reading in the correct sheet
    opts.SelectedVariableNames = {'BurstinessQt','SpeakerType','InfantAgeMonths','NumIeis'}; 
    CurrData_BurstinessTab = readtable('RecLvlBurstinessMeasure.xlsx',opts);
    NumRows = height(CurrData_BurstinessTab);
    BurstinessTab_Valdata = [BurstinessTab_Valdata;  CurrData_BurstinessTab]; %concat tables
    ValDataTypeCol_Str = [ValDataTypeCol_Str; repmat({ValDataType{i}}, NumRows, 1)]; %Add 
    ValDataTypeCol_Code = [ValDataTypeCol_Code; i*ones(NumRows,1)];
end

BurstinessTab_Valdata.ValDataType = ValDataTypeCol_Str;
BurstinessTab_Valdata.ValDataCode = ValDataTypeCol_Code;
BurstinessTab_Valdata = BurstinessTab_Valdata(contains(BurstinessTab_Valdata.SpeakerType,{'AN','CHNSP'}) & ...
                                                        ismember(BurstinessTab_Valdata.InfantAgeMonths,u_Ages),:);
b = boxchart(BurstinessTab_Valdata.ValDataCode*3,BurstinessTab_Valdata.BurstinessQt,'GroupByColor',categorical(BurstinessTab_Valdata.SpeakerType,{'CHNSP','AN'}), ...
    'Notch','on','MarkerStyle','.','MarkerSize',12,'BoxWidth',0.7,'BoxFaceAlpha',0.5);
b(1).BoxFaceColor = [0 0.4470 0.7410]; b(1).MarkerColor = [0 0.4470 0.7410];
b(2).BoxFaceColor = [0 0 0]; b(2).MarkerColor = [0 0 0];
plot(2:10,zeros(size(2:10)),':','LineWidth',2,'Color',[0.7 0.7 0.7]) %0 line
xlabel('Validation dataset'); title('B')
axis tight; ylim(axes2,[-1 1]); box(axes2,'on'); hold(axes2,'off');
set(axes2,'FontSize',24,'XGrid','on','XTick',[1 2 3]*3,'XTickLabel',{'L (5min)','H (5min; All Ad)','H (5min; T-Ad)'},'YGrid','on','YMinorGrid','on',...
    'YMinorTick','on','YTickLabel',{'','','','',''});
