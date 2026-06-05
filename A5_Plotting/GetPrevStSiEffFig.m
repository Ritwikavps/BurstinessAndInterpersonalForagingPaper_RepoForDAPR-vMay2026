function [] = GetPrevStSiEffFig(wCtrlTab,LENAClrs,ValDataClrs,ValDataTypeList,ValDataLegend)

%@author info; Aug 2024
%This function plots infant and adult previous step size betas for LENA day-long data (subplot A) and LENA 5 min, and human-labelled data (subplot B).
%Inputs: wCtrl_Tab: stats results table with resluts from response effects analysis WITH previous step size controls.
      %- LENAClrs: the line/marker colours for LENA day-long data, as RGP triplets. The first specified colour is for infant vocaliser, and the second colour is for adult. 
      %- ValDataClrs: the line/marker colours for LENA 5 min data, Hum labelled 5 min data (all adult vocs), and Hum labelled 5 min data (infant directed adult ONLY) (in that order).
        % Note that results for adult and infant vocalisers of the same data type (LENA 5 min, human labelled 5 min (all adult vocs), and human labelled 5 min (infant-directed adult only))
        % share a colour and are indicated by X axis labels instead.
      %- ValDataTypeList: the list of the types of validation data to be plotted (any subset of LENA 5 min, human labelled 5 min (all adult vocs), 
        % and human labelled 5 min (infant-directed adult only).
      %- ValDataLegend: the corresponding legend strings

%Determien hwether p value legends are necessary: get the pvalue vector from the table, define the vector of the different signioficance levels and the default flag (all false) for the 
% legend for each significance level. Essentialy, if p values are not all less than 0.001 or not all greater than 0.05, we need legends for the marker size for the different sig lvls.
% So, p_Siglvl_legend flags whether we need legends for the different sig lvls, and we initialise this vector as all false. 
PvalVec = wCtrlTab.PrevStP; SigLvls = [0.001 0.01 0.05]; p_SigLvl_legend = false(size(SigLvls));
if isempty(PvalVec(PvalVec >= 0.001)) %if every p value is less than 0.001
    disp('All p-values are less than 0.001')
elseif isempty(PvalVec(PvalVec < 0.05))  %if every p value is greater than or equal to 0.05 (ie, no significant results)
    disp('All p-values are greater than 0.05')
else
    for i = 1:numel(SigLvls) %go through the signoificance levels
        if ~isempty(PvalVec(PvalVec < SigLvls(i)))  %pick out pvalues less than the significance level value and check if that sub-vector is empty
            p_SigLvl_legend(i) = true; %if this sub-vector is not empty, this means that we have p values less than that significance level and need a legend for that marker size
        end
        PvalVec = PvalVec(PvalVec >= SigLvls(i)); %remove all p values less than the current sig level from the p value vector, so that only p values greater than the current sig level
        % are left, so we can run this test again for the othet sig lvls.
    end
end

u_RespToSpkr = {'ANRespToCHNSP','CHNSPRespToAN'}; %get list of response_to_spekar strings (ANRespToCHNSP, CHNSPRespToAN)
%check that the unique speaker list from the table is the same as the one we manually input
u_RespToSpkrFrmTab = sort(unique(wCtrlTab.ResponseType));
if numel(u_RespToSpkrFrmTab) == numel(u_RespToSpkr) %check if they both have the same number of elements 
    if height(u_RespToSpkrFrmTab) ~= height(u_RespToSpkr) %If one of them is a column vector and the other is a row vector, do a transpose
        u_RespToSpkrFrmTab = u_RespToSpkrFrmTab';
    end
    if ~isequal(u_RespToSpkrFrmTab,sort(u_RespToSpkr))
        error('The response-to-speaker list from the table is not as expected')
    end
else
    error('The number of entries in the response-to-speaker list from the table is not equal to the number expected')
end

YAxLims = [min(wCtrlTab.PrevStCI_Lwr)-0.005   max(wCtrlTab.PrevStCI_Upper)+0.005]; %set y axis limits (since the two subplots share an axis)
XCoord_ValData = [1 1.4]; %x coords for the validation data (we plot ChSp and Ad previous step size betas for the validation data in a cluster along the x axis; these co-ords set the
% center of these clusters).

%Pick out LENA day-long data and validation data subsets separately. Note that the validation data results are not separated by age, so there is only one prev step size effect 
% per validation dataset, while LENA day-long data has prev step size effects for each age block.
LENATab = wCtrlTab(strcmp(wCtrlTab.DataType,'LENA'),:); 
ValTab = wCtrlTab(~strcmp(wCtrlTab.DataType,'LENA'),:); 

%check that the validation data type list from the table is the same as the one we manually input
u_ValDataTypeFrmTab = sort(unique(ValTab.DataType));
if numel(u_ValDataTypeFrmTab) == numel(ValDataTypeList) %check if they both have the same number of elements
    if height(u_ValDataTypeFrmTab) ~= height(ValDataTypeList) %if one of them is a column vector and the other is a row vector, do a transpose
        u_ValDataTypeFrmTab = u_ValDataTypeFrmTab';
    end
    if ~isequal(u_ValDataTypeFrmTab,sort(ValDataTypeList))
        error('The validation data type list from the table is not as expected')
    end
else
    error('The number of entries in the validation data type list from the table is not equal to the number expected')
end

%plotting
figure1 = figure('PaperType','<custom>','PaperSize',[16 9],'Color',[1 1 1]); %create figure

%LENA-daylong data sub-plot
axes1 = axes('Parent',figure1,'Position',[0.105954465849387 0.210866752910738 0.423309982486865 0.605433376455369]); hold(axes1,'on'); % Create axes
for k = 1:2 %plot NaNs to set up legend
    plot(NaN*[3 4],[3 4],'Color',LENAClrs(k,:),'LineWidth',2) %plot NaN lines first according to the order of items in the legend, so the legend appears correctly
end
PlotPrevStSiEff(LENATab,LENAClrs(1,:),u_RespToSpkr{1}); %plot CHNSP speaker
PlotPrevStSiEff(LENATab,LENAClrs(2,:),u_RespToSpkr{2}); %plot AN speaker
title('A'); ylabel('Prev. step size effect (\beta)'); xlabel('Infant age (months)'); % Create axis labels
xlim(axes1,[3 18]); ylim(axes1,YAxLims); %set axis limits
box(axes1,'on'); hold(axes1,'off');
set(axes1,'FontSize',24,'GridAlpha',0.25,'GridLineStyle',':','GridLineWidth',0.75,'MinorGridAlpha',0.1,'MinorGridLineWidth',0.75,'XLimitMethod','tight','XTick',[3 6 9 18],...
    'YGrid','on','YLimitMethod','tight','YMinorGrid','on','YLimitMethod','tight','YMinorTick','on','YTick',[0.1 0.15 0.2 0.25 0.3],'YTickLabels',{'0.1','0.15','0.2','0.25','0.3'});
legend({'Infant (ChSp)','Adult (Ad)'},'Position',[0.113697312261933 0.22133435133911 0.0836252189141856 0.0730918499353169]);

%Validation data sub-plot
axes2 = axes('Parent',figure1,'Position',[0.565962625378124 0.210866752910738 0.423309982486865 0.606727037516172]); hold(axes2,'on'); % Create axes
for j = 1:numel(u_RespToSpkr) %go through the response-to-speaker list
    XVals = [XCoord_ValData(j)-0.05 XCoord_ValData(j) XCoord_ValData(j)+0.05]; %set the x co-ords where each validation data type beta value for the given speaker is plotted
    for i = 1:numel(ValDataTypeList) %go through the list of validation data type list
        ReqTab = ValTab(strcmp(ValTab.DataType,ValDataTypeList{i}) & strcmp(ValTab.ResponseType,u_RespToSpkr{j}),:); %subset relevant table
        PrevStEff_RespWinTest(ReqTab) %check that prev step size effect is the same for all response windows.
        TabToPlot = ReqTab(ReqTab.RespWin_Seconds == 1,:); %pick out a response window value
        errorbar(XVals(i),TabToPlot.PrevSt_Beta,abs(TabToPlot.PrevSt_Beta-TabToPlot.PrevStCI_Lwr),abs(TabToPlot.PrevSt_Beta-TabToPlot.PrevStCI_Upper),...
            'MarkerFaceColor',ValDataClrs(i,:),'MarkerEdgeColor',ValDataClrs(i,:),'Marker','o','LineStyle','none','Color',ValDataClrs(i,:),'MarkerSize',9.5,'LineWidth',1)
    end
end
title('B'); xlabel('Utterance');
xlim(axes2,[0.85 1.55]); ylim(axes2,YAxLims); box(axes2,'on'); hold(axes2,'off');
set(axes2,'FontSize',24,'GridAlpha',0.25,'GridLineStyle',':','GridLineWidth',0.75,'MinorGridAlpha',0.1,'MinorGridLineWidth',0.75,'XTick',XCoord_ValData,'XTickLabel',{'ChSp','Ad'},...
    'YGrid','on','YLimitMethod','tight','YMinorGrid','on','YTick',[0.1 0.15 0.2 0.25 0.3],'YTickLabels',{'','','','',''});
legend(ValDataLegend,'Position',[0.783712735683404 0.70116429553104 0.190017513134851 0.107373868046572]);

% Uncomment below for p-value legend, if necessary
% %This is simply legend for the p value levels, if it is necessary.
% annotation(figure1,'ellipse',[0.339269363146964 0.862560479901696 0.00292067354113634 0.00382983940151427],'FaceColor',[0 0 0]); %ellipse
% annotation(figure1,'textbox',[0.348583594021549 0.842176590712228 0.10926094890511 0.0478260869565217],'String',{'p < 0.05'},'FontSize',24,...
%     'FontName','Helvetica Neue','FitBoxToText','off','EdgeColor','none'); %textbox
% annotation(figure1,'ellipse',[0.469644305410684 0.860082165155719 0.00542065809296499 0.00764731152047404],'FaceColor',[0 0 0]); %ellipse
% annotation(figure1,'textbox',[0.479154597767735 0.842176590712228 0.10926094890511 0.0478260869565217],'String',{'p < 0.01'},'FontSize',24,...
%     'FontName','Helvetica Neue','FitBoxToText','off','EdgeColor','none'); %textbox
% annotation(figure1,'ellipse',[0.597067740315889 0.858843007782733 0.00785926698338091 0.0118271636825417],'FaceColor',[0 0 0]); %ellipse
% annotation(figure1,'textbox',[0.608972502220672 0.842176590712227 0.121578467153285 0.0478260869565217],'String',{'p < 0.001'},'FontSize',24,...
%     'FontName','Helvetica Neue','FitBoxToText','off','EdgeColor','none');

%-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%This functiond tests to make sure that all values of prev st size beta, pvalue and CIs are the same for all response window values
    function [] = PrevStEff_RespWinTest(InputTab)

        RndTest = 0; %initialise number of tests to run
        while RndTest < 15 %terminate if 15 tests have been run
            RespWins = randi([1 10],1,2); %pick two response window values at random
            %Note that for LENA daylong data, this check looks at all 4 ages (4, 6, 9, and 18 months) for the two sample response windows here, since LENA day-long data has 
            % previous step size effect results for all 4 ages, for each response window. However, for validation data, this check looks at the previous step size effect for the
            % entire data set, for the two sample response windows, since we don't separate teh validation data into age blocks.
            if ~isequal(InputTab.PrevSt_Beta(InputTab.RespWin_Seconds == RespWins(1)),InputTab.PrevSt_Beta(InputTab.RespWin_Seconds == RespWins(2)))...
                    || ~isequal(InputTab.PrevStP(InputTab.RespWin_Seconds == RespWins(1)),InputTab.PrevStP(InputTab.RespWin_Seconds == RespWins(2))) ...
                    || ~isequal(InputTab.PrevStCI_Lwr(InputTab.RespWin_Seconds == RespWins(1)),InputTab.PrevStCI_Lwr(InputTab.RespWin_Seconds == RespWins(2))) ...
                    || ~isequal(InputTab.PrevStCI_Upper(InputTab.RespWin_Seconds == RespWins(1)),InputTab.PrevStCI_Upper(InputTab.RespWin_Seconds == RespWins(2))) %check that p values, response effect values,
                %and Confidence intervals are same for the two response windows
                error('Diff response windows have different stat results for prev. step size tests.') %error if not
            end
            RndTest = RndTest + 1; %increment number of tests run
        end
    end

%----------------------------------------------------------------------------------------------------------------------
%function to plot individual lines and bounded lines for a given speaker type: given the input table (InputTab) and the type of speaker and responder (RespToSpkrType; eg. ANRespToCHNSP) 
% whose prev. step size betas need to be plotted, this function plots the prev. step size betas for that step type as a function of infant age. Note that since the prev. step size
% effect is independent of the response window, we are not plotting this for different response window values. LineClr specifies the colour for the line. 
%The output PvalSigLvlFlag flags for whether there are p values greater than 0.001, so different significance levels can be plotted with appropriate legends. 
    function [] = PlotPrevStSiEff(InputTab,LineClr,RespToSpkrType)

        if ~strcmp(unique(InputTab.DataType),'LENA') %check to make sure that the table only has LENA day-long results
            error('Table is not just LENA day-long stats results')
        end

        SubTab = InputTab(strcmp(InputTab.ResponseType,RespToSpkrType),:); %subset table for relevant speaker type
        PrevStEff_RespWinTest(SubTab) %Check that there is no variation in p value and effect size for the previous step size effect as a function of response window
        
        tabToPlot = SubTab(SubTab.RespWin_Seconds == SubTab.RespWin_Seconds(1),:); %subset table for one response window value (since all response windows have the same stats results)
        tabToPlot = sortrows(tabToPlot,'InfAge_Months'); %sort by age
        Xvar_line = 'InfAge_Months'; Yvar_line = 'PrevSt_Beta';
        Xvar_patch = 'InfAge_Months'; Yvar_patch1 = 'PrevStCI_Lwr'; Yvar_patch2 = 'PrevStCI_Upper';
        %specify name value arguments for the patch
        NameValStruct.FaceClr= LineClr; NameValStruct.FaceAlphaVal = 0.1; NameValStruct.EdgeClr = 'none'; NameValStruct.EdgeAlphaVal = 1; 
        DrawLineAndPatchForCI(tabToPlot,Xvar_line,Yvar_line,LineClr,Xvar_patch,Yvar_patch1,Yvar_patch2,NameValStruct); %function to draw patch and line;
        %(see relevant function)

        SigTab = tabToPlot(tabToPlot.PrevStP < 0.001,:); %plot effect sizes at significance level p < 0.001 
        plot(SigTab.InfAge_Months,SigTab.PrevSt_Beta,'.','MarkerSize',35,'Color',LineClr) 
        
        %check if any p values are grater than 0.001: filter for p values greater than 0.001, and if this list is NOT empty, we need to plot other siginificance levels
        if ~isempty(tabToPlot.PrevStP(tabToPlot.PrevStP > 0.001))
            SigTab = tabToPlot(tabToPlot.PrevStP < 0.05,:);
            plot(SigTab.InfAge_Months,SigTab.PrevSt_Beta,'.','MarkerSize',10,'Color',LineClr)
            SigTab = tabToPlot(tabToPlot.PrevStP < 0.01,:);
            plot(SigTab.InfAge_Months,SigTab.PrevSt_Beta,'.','MarkerSize',20,'Color',LineClr)   
        end    
    end

end

%-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%THIS IS IN CASE WE HAVE p-VALUS THAT ARE BETWEEN 0.001 and 0.05. For now, that isn't the case and we don't have to deal with this. IF that becomes the case, write appropriate 
% function for that case. For now, this is bulit into the plotting function but we can likely streamline this more if needed.
% for i = 1:numel(p_SigLvl_legend)
%     if p_SigLvl_legend(i)
% 
% end
%-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
