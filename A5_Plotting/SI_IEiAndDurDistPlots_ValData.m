%@author info;
%This script plots the IEI and duration distribtions for validation data, without subsetting for age. Distributions represent data after vocs of the same type 
% (CHNSP, CHNNSP, or AN) with 0 IEI separation have been merged together.

%Duration and IEI are both skewed distributions with long tails as is evident from figures with range, mean, and median of durations in SI, as well as from previous 
% figures showing IEI distributions in [redacted paper for DAPR], from a subset of the current data. So, this is the strategy we use here, to get a good visualisation:
% This is adapted from 'Head/tail Breaks: A New Classification Scheme for Data with a Heavy-tailed Distribution by Bin Jiang' where the author demonstrated how
% to partition data by recursively using the mean of the data, selecting the 'tail' (the portion of the data greater than the mean) and repeating this. Here, instead
% of the mean, I use a percentile value (10 percentile). This allows for a non-parametric way to do this that is informed by the underlying structure of the data
% while providing enough bins to get a proper distribution viz (in the Jiang paper, the goal is to obtain broad clusters of data, so the purposes differ a bit).
% In showing the distributions, I do want to show the untransformed data without doing any fitting, so this was the best way to do 
% that without using more complex binning strategies (which is not the goal here--I simply want the reader to have a sense of what the data looks like).
% I choose to represent the data as a distribution of probabilty (normalised counts, c_i, such that sum of all c_i = 1. Note that this is distinct from the pdf
% because the pdf normalises such that the area under the curve is 1) based on this process as well as a complementary cdf (1-cdf) to highlight how the tails of the
% distributions look like. In the counts representation, the tails are long but sparse for high values, resulting in a spiky distribtution that is somewhat difficult
% to make sense of easily (however, much less so than when using other methods, such as log binning or regular binning). The complementary cdf provides a smoother 
% visualisation in this case without having to resort to fitting procedures. The ccdf quantifies probability of X > x, for any value of x on the x axis.
%
% I use 10th percentile values for the validation data because there are fewer data points compared to LENA data. 
clearvars; clc
DataClrs = [0 0 0; 178 24 43; 33 102 172]/256;

%This is the base path to the files that may undergo change
BasePath = '~/BaseDataPath/Data/';
destinationpath_Dur = strcat(BasePath,'ResultsTabs/UttDurTabs/'); %get destination path to write duration tabs

%Read meta data table
cd(strcat(BasePath,'MetadataFiles/'));
MetadataTab = readtable('MergedTSAcousticsMetadata.csv');

%get file path and string to remove from file name to get duration tabs: L5min
L5_FilePath = strcat(BasePath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A10_NoAcoustics_0IviMerged_L5min/');
L5_FileStr = '_NoAcoustics_0IviMerged_LENA5min.csv'; %the string to remove from file names

%get file path and string to remove from file name to get duration tabs: H5min
H5_FilePath = strcat(BasePath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A9_NoAcoustics_0IviMerged_Hum/');
H5_FileStr = '_NoAcoustics_0IviMerged_Hum.csv'; %the string to remove from file names

%get file path and string to remove from file name to get duration tabs: H5min, child-directed adult only
H5_TAd_FilePath = strcat(BasePath,'HUMLabelData/A2_HUMLabelData_PostCleanUp/A11_NoAcoustics_0IviMerged_Hum_ChildDirANOnly/');
H5_TAd_FileStr = '_NoAcoustics_0IviMerged_ChildDirANOnly_Hum.csv'; %the string to remove from file names

%put paths and strings into cell arrays + other stuff
ValDataPath = {L5_FilePath,H5_FilePath,H5_TAd_FilePath};
ValDataStrs = {L5_FileStr,H5_FileStr,H5_TAd_FileStr};
ValDataType = {'L5min','H5min','H5min_TAd'}; %string to id validation data and to write duration table
ValDataSuffixForIeiTabDir = {'LENA5min','H','H_ChildDirANOnly'}; %string to cd into dirs with in Iei tables
ValDataSuffixForIeiTab = {'LENA5min','Hum','ChildDirANOnly_Hum'}; %string to read Iei tables within those directories

%go into folders, get files, etc and get duration table and write to file. 
for i = 1:numel(ValDataPath)
    cd(ValDataPath{i});
    ValDataFiles = dir(strcat('*',ValDataStrs{i}));
    %get duration table and write to file
    DurationTab{i} = GetUttDurations(ValDataFiles,MetadataTab,ValDataStrs{i}); %user defined function
    cd(destinationpath_Dur)
    writetable(DurationTab{i},strcat('Durations_',ValDataType{i},'.csv'));
end

%Get IeiTabs
for i = 1:numel(ValDataType)
    cd(strcat(BasePath,strcat('ResultsTabs/ResponseAnalyses/ResponseEffect_w_CurrPrevStSizeControl_',ValDataSuffixForIeiTabDir{i},'/')));
    IeiTab_AnVoc{i} = readtable(strcat('CurrPrevStSize_',ValDataSuffixForIeiTab{i},'_CHNSPRespToAN_IviOnly.csv'));
    IeiTab_ChnspVoc{i} = readtable(strcat('CurrPrevStSize_',ValDataSuffixForIeiTab{i},'_ANRespToCHNSP_IviOnly.csv'));
end

%-----------------------------------------------------
%PLOTTING
%-----------------------------------------------------
%plotting: IEI distribution, ChSp
for i = 1:numel(IeiTab_ChnspVoc)-1 %loop through different val data types; CHNSP is the same for hum label data with all adult vocs and only child  
    % directed adult vocs, so we don't need the child directed adult voc only dataset
    [X{i},X_Edges{i},Y_Cts{i},Y_cdf{i},Y_ccdf{i},Y_probs{i},SameBinEdgeFlag] = GetVecsToPlot(IeiTab_ChnspVoc{i}.CurrIVI);
end
% %Below is simply a demo of how SameBinEdgeFlag is used. Commenting out for now, only used for de-bugging/verifying data trends. Please feel free to uncomment 
% and/or re-implement similar if statements for other plots below.
% if SameBinEdgeFlag
%     disp('There are bin edges that are effectively the same')
%     disp('CHNSP IEI')
% end
figure1 = figure('PaperType','<custom>','PaperSize',[20.5 9],'Color',[1 1 1]);

%IEI frequency disribution
axes1 = axes('Parent',figure1,'Position',[0.107142857142858 0.145085803432137 0.357804232804232 0.808459338373535]); hold(axes1,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_probs{i},'Color',DataClrs(i,:),'LineWidth',1.5);
end
title('A'); ylabel('Probability'); xlabel('IEI, \Deltat (s)'); 
xlim(axes1,[0.1 220]); ylim(axes1,[-0.001 0.101]); hold(axes1,'off');
set(axes1,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XScale','log','XTick',[0.1 1 10 100],'XTickLabel',...
    {'0.1','1','10','100'},'YGrid','on','YTick',[0 0.02 0.04 0.06 0.08 0.1],'YLimitMethod','tight','ZLimitMethod','tight');
legend(axes1,{'L (5min)','H (5min; All Ad)'});

%IEI ccdf
axes2 = axes('Parent',figure1,'Position',[0.595473184223182 0.144442577703108 0.357804232804232 0.809102564102564]); hold(axes2,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_ccdf{i},'Color',DataClrs(i,:),'LineWidth',1.5);
end
title('B'); ylabel('P(\DeltaT > \Deltat)'); xlabel('IEI, \Deltat (s)'); 
xlim(axes2,[-1 173]); ylim(axes2,[0.000117697612055 1]); hold(axes2,'off');
set(axes2,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorGrid','on','XMinorTick','on','YGrid','on','YLimitMethod','tight','YMinorTick','on',...
    'YScale','log','ZLimitMethod','tight');
annotation(figure1,'textbox',[0.00330687830687823 0.00920861242613296 0.0357379219060225 0.0351014040561622],'String',{'CHNSP'});

%-----------------------------------------------------

%plotting: IEI distribution, Adult vocs
clearvars X X_Edges Y_Cts Y_cdf Y_ccdf Y_probs
for i = 1:numel(IeiTab_AnVoc)
    [X{i},X_Edges{i},Y_Cts{i},Y_cdf{i},Y_ccdf{i},Y_probs{i},~] = GetVecsToPlot(IeiTab_AnVoc{i}.CurrIVI);
end
figure1 = figure('PaperType','<custom>','PaperSize',[20.5 9],'Color',[1 1 1]);

%IEI frequency disribution
axes1 = axes('Parent',figure1,'Position',[0.111113737354638 0.1484375 0.357804232804232 0.809775641025641]); hold(axes1,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_probs{i},'Color',DataClrs(i,:),'LineWidth',1.5);
end
title('A');ylabel('Probability');xlabel('IEI, \Deltat (s)');
xlim(axes1,[0.1 270]); ylim(axes1,[-0.001 0.101]); hold(axes1,'off');
set(axes1,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XScale','log','XTickLabel',{'0.1','1','10','100'},'YGrid','on',...
    'YLimitMethod','tight','YTick',[0 0.02 0.04 0.06 0.08 0.1],'ZLimitMethod','tight');
legend(axes1,{'L (5min)','H (5min; All Ad)','H (5min; T-Ad)'});

%IEI ccdf
axes2 = axes('Parent',figure1,'Position',[0.595473184223182 0.149110576923077 0.357804232804232 0.809102564102564]); hold(axes2,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_ccdf{i},'Color',DataClrs(i,:),'LineWidth',1.5);
end
title('B');ylabel('P(\DeltaT > \Deltat)'); xlabel('IEI, \Deltat (s)');
xlim(axes2,[0 241]); ylim(axes2,[0.000151399188712 1]); hold(axes2,'off');
set(axes2,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorGrid','on','YGrid','on','YLimitMethod','tight','YMinorTick','on','YScale','log',...
    'ZLimitMethod','tight');
annotation(figure1,'textbox',[0.0039682539682539 0.0122738912872874 0.0281084656084656 0.03515625],'String',{'Adult'});
%-----------------------------------------------------

%plotting: duration distribution, Chnsp
clearvars X X_Edges Y_Cts Y_cdf Y_ccdf Y_probs
for i = 1:numel(DurationTab)-1
    CurrDurTab = DurationTab{i}; 
    DurChnspTab = CurrDurTab(contains(CurrDurTab.Speaker,'CHNSP'),:); %get duration tab with CHNSP only
    [X{i},X_Edges{i},Y_Cts{i},Y_cdf{i},Y_ccdf{i},Y_probs{i}, ~] = GetVecsToPlot(DurChnspTab.Duration);
end
figure1 = figure('PaperType','<custom>','PaperSize',[20.5 9],'Color',[1 1 1]);

%duration frequency disribution
axes1 = axes('Parent',figure1,'Position',[0.107142857142858 0.14576802507837 0.357804232804232 0.810853227232537]); hold(axes1,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_probs{i},'Color',DataClrs(i,:),'LineWidth',1.5);
end
title('A');ylabel('Probability');xlabel('Duration, d (s)');
xlim(axes1,[0.09 28]); ylim(axes1,[-0.002 0.2]); hold(axes1,'off');
set(axes1,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XScale','log','XTickLabel',{'0.1','1','10'},'YGrid','on','YLimitMethod',...
    'tight','YTick',[0 0.04 0.08 0.12 0.16 0.2],'ZLimitMethod','tight');
legend(axes1,{'L (5min)','H (5min; All Ad)'});

%duration ccdf
axes2 = axes('Parent',figure1,'Position',[0.595473184223182 0.147518688208343 0.357804232804232 0.809102564102564]); hold(axes2,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_ccdf{i},'Color',DataClrs(i,:),'LineWidth',1.5);
end
title('B');ylabel('P(D > d)'); xlabel('Duration, d (s)');
xlim(axes2,[0 26.8]); ylim(axes2,[0.00011 1]); hold(axes2,'off');
set(axes2,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorGrid','on','XMinorTick','on','YGrid','on','YLimitMethod','tight','YMinorTick','on',...
    'YScale','log','ZLimitMethod','tight');
annotation(figure1,'textbox',[0.00462962962962963 0.0117554858934169 0.0320767195767196 0.0352664576802508],'String',{'Chnsp'});
%-----------------------------------------------------

%plotting: duration distribution, Adult
clearvars X X_Edges Y_Cts Y_cdf Y_ccdf Y_probs
for i = 1:numel(DurationTab)
    CurrDurTab = DurationTab{i}; 
    DurAnTab = CurrDurTab(contains(CurrDurTab.Speaker,'AN'),:); %get duration tab with CHNSP only
    [X{i},X_Edges{i},Y_Cts{i},Y_cdf{i},Y_ccdf{i},Y_probs{i}, ~] = GetVecsToPlot(DurAnTab.Duration);
end
figure1 = figure('PaperType','<custom>','PaperSize',[20.5 9],'Color',[1 1 1]);

%duration frequency disribution
axes1 = axes('Parent',figure1,'Position',[0.101190476190477 0.150905285191 0.357804232804232 0.796282051282051]); hold(axes1,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_probs{i},'Color',DataClrs(i,:),'LineWidth',1.5);
end
title('A');ylabel('Probability');xlabel('Duration, d (s)');
xlim(axes1,[0.1 20]); ylim(axes1,[-0.002 0.277]); hold(axes1,'off');
set(axes1,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XScale','log','XTick',[0.1 1 10],'XTickLabel',{'0.1','1','10'},'YGrid',...
    'on','YLimitMethod','tight','ZLimitMethod','tight');
legend(axes1,{'L (5min)','H (5min; All Ad)','H (5min; T-Ad)'});

%duration ccdf
axes2 = axes('Parent',figure1,'Position',[0.60473244348244 0.150643642072214 0.357804232804232 0.797551020408163]); hold(axes2,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_ccdf{i},'Color',DataClrs(i,:),'LineWidth',1.5);
end
title('B');ylabel('P(D > d)'); xlabel('Duration, d (s)');
xlim(axes2,[0 15.2]); ylim(axes2,[0.00014 1]); hold(axes2,'off');
set(axes2,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorGrid','on','YGrid','on','YLimitMethod','tight','YMinorTick','on','YScale','log',...
    'ZLimitMethod','tight');
annotation(figure1,'textbox',[0.00066137566137573 0.960538461538465 0.0281084656084656 0.0353218210361067],'String',{'Adult'});


%----------------------------------------------------------------------------------------------------------------------------------------------
%This function takes in the time series and a percentile value and bins the time series using a histogram. To do this, we first compute the histogram bin
% edges by partitioning data at the 10 percent level recursively (However, there is flexibility in choosing this, using the ReqPrctile input). That is, the 
% input TS is first partitioned at 10 percentile. Then the rest of the data (after removing the everything less than the 10 percentile value) is partitioned 
% again at the 10 percentile level, and so on, till the partitioning results in only 1 remaning data point. Each succesive 10 percentile value is stored. 
% The bin edges are given as follows: the first bin is min of data to 1st 10 percentile value; the second bin is from the first 1- percentile value to the second
% 10 percentile values, etc. The last bin is from the last 10 percentile value to max value in the data.
% 
% Inputs: Time series to be binned (TS) and the required percentile level for binning (ReqPrctile)
% Outputs: X_Edges: bin edges; Y_Cts: bin counts (raw counts); Y_cdf: y values for the cdf; Y_probs: y values for normalised probability; 
%          SameBinEdgeFlag: flags true if there are a series of bin edges that are effectively the same (with allowed variations less than or equal 
%          to 10^-5) that are consecutive and effectively equal to the min value in the data.
function [X_Edges,Y_Cts,Y_cdf,Y_probs,SameBinEdgeFlag] = GetPtsToPlot(TS,ReqPrctile)

    SameBinEdgeFlag = false;
    Ctr = 0; %initialise counter variable
    TS_Copy = TS; %get copy of the input TS
    
    while true %execute till break
        CurrPrcVal = prctile(TS,ReqPrctile); %get the percentile value of the data for the current partition 
        TS = TS(TS>CurrPrcVal); %remove all values less than or equal to the current percentile value
        if numel(TS) > 1 %if the updated TS has more than one element, continue
            Ctr = Ctr + 1; %update counter
            PartitionsVals(Ctr) = CurrPrcVal; %store partitin values 
        else %if the updated TS only has one element, we can stop
            break
        end
    end
    
    X_Edges = [min(TS_Copy) PartitionsVals max(TS_Copy)]; %get bin edges

    %Now, we have an issue where there are *a* lot of infant durations at 0.6 s. This means that the first few bin edges are 0.6 (with perhaps differences of the order
    % of ~ 10^-10 or so). The first bin is simply [0.6 0.6]. This means that the histogram counts this as 0 when there are a few thousand values to actually be 
    % counted. This is a hack-y fix based on knowing what the data looks like.
    diffEdge = diff(X_Edges); %get diff of bin edges. ith diff is (i+1)th-ith element of X_Edges
    NoDiffInds = find(diffEdge < 10^-5); %find indices of all diff values that are less than 10^-5
    Diff_NoDiffInds = diff(NoDiffInds)-1; %get the diff of this set of indices. This is to check if all these bin edges that are the same (except for variations of 
    % the order of 10^-5) are consecutive. This hack-y fix does not account for cases when these are non-consecutive, nor when they aren't for the min value in 
    % the data. So, the ( -1) changes the diff values that are equal to 1 to 0. For consecutive bin edges, the diff in indices would be 1. With the -1 applied, 
    % we can id consecutive indices as the ones that have turned into 0.
    
    if sum(abs(Diff_NoDiffInds)) ~= 0 %Take the sum of the diff of indices for bin edge values that are effectively the same (accounting for variations of the
        %order of ~10^-5 or less), after 1 has been subtracted from the diff of indices. The abs value makes it so that if there are any that are non-consecutive,
        % we will get a sum greater than 0. There shouldn't be any -ve values here, but this is a 'just in case' thing.
        error('Some bin edges are not consecutive.')
    end

    %Now, check if NoDiffInds is empty. If it is not empty, that means that there are bin edges that are essentially the same.
    if ~isempty(NoDiffInds)
        %Check if the first of these indices correspond to a bin edge of value equal to the min of data.
        if X_Edges(NoDiffInds(1)) == min(TS_Copy)
            %If yes, remove all bin edges that are the same value as the min value. The last index + 1 corresponds to the last incidence of the series of bin edges 
            % that are effectively the same. So, we retain last index + 1.
            X_Edges = X_Edges(NoDiffInds(end)+2:end); 
            X_Edges = [min(TS_Copy) X_Edges]; %Then, add the min value back
            SameBinEdgeFlag = true;
        else
            %If the first bin edge in the series of effectively same bin edge is not the min value, throw an error.
            error('The first bin edge is not minimum value of the data')
        end
    end
    
    TempFig = figure; %temp figure ofr histogram
    h = histogram(TS_Copy,X_Edges,'Normalization','cdf'); %get histogram (using the TS copy) and normalise as cdf
    Y_Cts = h.BinCounts; %get the raw counts for each bin
    Y_cdf = h.Values; %get cdf values
    h = histogram(TS_Copy,X_Edges,'Normalization','probability'); %get histogram (using the TS copy) and normalise as cdf
    Y_probs = h.Values;
    close(TempFig) %close the temp fig
end

%----------------------------------------------------------------
%This function gets the ccdf, cdf and frequency vectors to plot as well as the Xvalues (bin centres) and the Bin edges. 
% Inputs are the relevanr time series vector, eg. CHNSP IEI (IPTSVec).
% Outputs are the X values (the bin centres; X), the bin edges (X_Edges), raw counts (Y_Cts), probability, cdf, and ccdf values (Y_probs,Y_cdf, Y_ccdf).
% For an explanation of the output SameBinEdgeFlag, see function GetPtsToPlot, defined in this script.
function [X,X_Edges,Y_Cts,Y_cdf,Y_ccdf,Y_probs,SameBinEdgeFlag] = GetVecsToPlot(TimeSeries)
    [X_Edges,Y_Cts,Y_cdf,Y_probs,SameBinEdgeFlag] = GetPtsToPlot(TimeSeries,10); %get bin edges, counts, and cdf values (using 5 percentile for partitioning)
    Y_ccdf_Temp = 1-Y_cdf; %get ccdf
    Y_ccdf_Temp(Y_ccdf_Temp < 10^-6) = NaN; %truncate ccdf by removing values with probability < 10^-6
    Y_ccdf = Y_ccdf_Temp;
    X = 0.5*(X_Edges(1:end-1)+X_Edges(2:end)); %get bin mid points values
end
