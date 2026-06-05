%@author info;
%This script plots the IEI and duration distribtions for LENA day-long data, subsetted by infant age. Distributions represent data after vocs of the same type 
% (CHNSP, CHNNSP, or AN) with 0 IEI separation have been merged together.

%Duration and IEI are both skewed distributions with long tails as is evident from figures with range, mean, and median of durations in SI, as well as from previous 
% figures showing IEI distributions in [redacted paper for DAPR], from a subset of the current data. So, this is the strategy we use here, to get a good visualisation:
% This is adapted from 'Head/tail Breaks: A New Classification Scheme for Data with a Heavy-tailed Distribution' by Bin Jiang where the author demonstrated how
% to partition data by recursively using the mean of the data, selecting the 'head' (the portion of the data greater than the mean) and repeating this. Here, instead
% of the mean, I use a percentile value (5 percentile). This allows for a non-parametric way to do this that is informed by the underlying structure of the data
% while providing enough bins to get a proper distribution viz (in the Jiang paper, the goal is to obtain broad clusters of data, so the purposes differ a bit).
% In showing the distributions, I do want to show the untransformed data without doing any fitting, so this was the best way to do 
% that without using more complex binning strategies (which is not the goal here--I simply want the reader to have a sense of what the data looks like).
% I choose to represent the data as a distribution of probabilty (normalised counts, c_i, such that sum of all c_i = 1. Note that this is distinct from the pdf
% because the pdf normalises such that the area under the curve is 1) based on this process as well as a complementary cdf (1-cdf) to highlight how the tails of the
% distributions look like. In the counts representation, the tails are long but sparse for high values, resulting in a spiky distribtution that is somewhat difficult
% to make sense of easily (however, much less so than when using other methods, such as log binning or regular binning). The complementary cdf provides a smoother 
% visualisation in this case without having to resort to fitting procedures. The ccdf quantifies probability of X > x, for any value of x on the x axis. 
clearvars; clc
AgeClrs = [102 204 238; 34 136 51; 204 187 68; 170 51 119]/256;

%This is the base path to the files that may undergo change
BasePath = '~/BaseDataPath/Data/';
destinationpath_Dur = strcat(BasePath,'ResultsTabs/UttDurTabs/'); %get destination path to write duration tabs

%Read meta data table
cd(strcat(BasePath,'MetadataFiles/'));
MetadataTab = readtable('MergedTSAcousticsMetadata.csv');

%get file path and string to remove from file name to get duration tabs
FilePath = strcat(BasePath,'/LENAData/A8_NoAcoustics_0IviMerged_LENA/');
FileStr = '_NoAcoustics_0IviMerged_LENA.csv'; %the string to remove from file names

%go into folder, get files, etc
cd(FilePath);
LENAFiles = dir(strcat('*',FileStr));

%get duration table and write to file
DurationTab = GetUttDurations(LENAFiles,MetadataTab,FileStr);
cd(destinationpath_Dur)
writetable(DurationTab,'Durations_LENAdaylong.csv');

%Get IeiTabs
cd(strcat(BasePath,'ResultsTabs/ResponseAnalyses/ResponseEffect_w_CurrPrevStSizeControl_LENA/'));
IeiTab_AnVoc = readtable('CurrPrevStSize_LENA_CHNSPRespToAN_IviOnly.csv');
IeiTab_ChnspVoc = readtable('CurrPrevStSize_LENA_ANRespToCHNSP_IviOnly.csv');

U_AgeMnths = [3 6 9 18]; %ages

%-----------------------------------------------------
%PLOTTING
%-----------------------------------------------------
%plotting: IEI distribution, ChSp
[X,X_Edges,Y_Cts,Y_cdf,Y_ccdf,Y_probs,SameBinEdgeFlag] = GetVecsToPlot(IeiTab_ChnspVoc.CurrIVI,IeiTab_ChnspVoc.AgeMonths,U_AgeMnths);
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
    plot(X{i},Y_probs{i},'Color',AgeClrs(i,:),'LineWidth',1.5);
end
title('A'); ylabel('Probability'); xlabel('IEI, \Deltat (s)'); 
xlim(axes1,[0.6 14000]); ylim(axes1,[-0.0005 0.06]); hold(axes1,'off');
set(axes1,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XScale','log','XTick',[1 10 100 1000 10000],'XTickLabel',...
    {'1','10','100','1000','10000'},'YGrid','on','YLimitMethod','tight','ZLimitMethod','tight');
legend(axes1,{'3 months','6 months','9 months','18 months'},...
    'Position',[0.277056217368924 0.852574102964119 0.181998676373263 0.0881435257410296],'NumColumns',2);

%IEI ccdf
axes2 = axes('Parent',figure1,'Position',[0.595473184223182 0.144442577703108 0.357804232804232 0.809102564102564]); hold(axes2,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_ccdf{i},'Color',AgeClrs(i,:),'LineWidth',1.5);
end
title('B'); ylabel('P(\DeltaT > \Deltat)'); xlabel('IEI, \Deltat (s)'); 
xlim(axes2,[-60 12000]); ylim(axes2,[4.592345071e-05 1]); hold(axes2,'off');
set(axes2,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorGrid','on','XMinorTick','on','XTick',[0 3000 6000 9000 12000],'YGrid','on',...
    'YLimitMethod','tight','YMinorTick','on','YScale','log','ZLimitMethod','tight');
annotation(figure1,'textbox',[0.00330687830687823 0.00920861242613296 0.0357379219060225 0.0351014040561622],'String',{'CHNSP'});

%-----------------------------------------------------

%plotting: IEI distribution, Adult vocs
[X,X_Edges,Y_Cts,Y_cdf,Y_ccdf,Y_probs,~] = GetVecsToPlot(IeiTab_AnVoc.CurrIVI,IeiTab_AnVoc.AgeMonths,U_AgeMnths);
figure1 = figure('PaperType','<custom>','PaperSize',[20.5 9],'Color',[1 1 1]);

%IEI frequency disribution
axes1 = axes('Parent',figure1,'Position',[0.111113737354638 0.1484375 0.357804232804232 0.809775641025641]); hold(axes1,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_probs{i},'Color',AgeClrs(i,:),'LineWidth',1.5);
end
title('A');ylabel('Probability');xlabel('IEI, \Deltat (s)');
xlim(axes1,[0.6 15000]); ylim(axes1,[-0.001 0.08]); hold(axes1,'off');
set(axes1,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XScale','log','XTick',[1 10 100 1000 10000],'XTickLabel',...
    {'1','10','100','1000','10000'},'YGrid','on','YLimitMethod','tight','YTick',[0 0.02 0.04 0.06 0.08],'ZLimitMethod','tight');
legend(axes1,{'3 months','6 months','9 months','18 months'},'Position',[0.28042328042328 0.8578125 0.181878306878307 0.08828125],'NumColumns',2);

%IEI ccdf
axes2 = axes('Parent',figure1,'Position',[0.595473184223182 0.149110576923077 0.357804232804232 0.809102564102564]); hold(axes2,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_ccdf{i},'Color',AgeClrs(i,:),'LineWidth',1.5);
end
title('B');ylabel('P(\DeltaT > \Deltat)'); xlabel('IEI, \Deltat (s)');
xlim(axes2,[-50 12150]); ylim(axes2,[2.1100556722e-05 1]); hold(axes2,'off');
set(axes2,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorGrid','on','XTick',[0 4000 8000 12000],'YGrid','on','YLimitMethod','tight',...
    'YMinorTick','on','YScale','log','ZLimitMethod','tight');
annotation(figure1,'textbox',[0.0039682539682539 0.0122738912872874 0.0281084656084656 0.03515625],'String',{'Adult'});
%-----------------------------------------------------

%plotting: duration distribution, Chnsp
DurChnspTab = DurationTab(contains(DurationTab.Speaker,'CHNSP'),:); %get duration tab with CHNSP only
[X,X_Edges,Y_Cts,Y_cdf,Y_ccdf,Y_probs, ~] = GetVecsToPlot(DurChnspTab.Duration,DurChnspTab.InfAgeMnth,U_AgeMnths);
figure1 = figure('PaperType','<custom>','PaperSize',[20.5 9],'Color',[1 1 1]);

%duration frequency disribution
axes1 = axes('Parent',figure1,'Position',[0.107142857142858 0.14576802507837 0.357804232804232 0.810853227232537]); hold(axes1,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_probs{i},'Color',AgeClrs(i,:),'LineWidth',1.5);
end
title('A');ylabel('Probability');xlabel('Duration, d (s)');
xlim(axes1,[0.57 37]); ylim(axes1,[-0.01 0.275]); hold(axes1,'off');
set(axes1,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XScale','log','XTick',[0.6 1 2 4 10 30],'XTickLabel',...
    {'0.6','1','2','4','10','30'},'YGrid','on','YLimitMethod','tight','YTick',[0 0.05 0.1 0.15 0.2 0.25],'ZLimitMethod','tight');
legend(axes1,{'3 months','6 months','9 months','18 months'},'NumColumns',2);

%duration ccdf
axes2 = axes('Parent',figure1,'Position',[0.595473184223182 0.147518688208343 0.357804232804232 0.809102564102564]); hold(axes2,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_ccdf{i},'Color',AgeClrs(i,:),'LineWidth',1.5);
end
title('B');ylabel('P(D > d)'); xlabel('Duration, d (s)');
xlim(axes2,[0 28]); ylim(axes2,[4.680906525e-05 1]); hold(axes2,'off');
set(axes2,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorGrid','on','XMinorTick','on','XTick',[0 5 10 15 20 25],'XTickLabel',...
    {'0','5','10','15','20','25'},'YGrid','on','YLimitMethod','tight','YMinorTick','on','YScale','log','ZLimitMethod','tight');
annotation(figure1,'textbox',[0.00462962962962963 0.0117554858934169 0.0320767195767196 0.0352664576802508],'String',{'Chnsp'});
%-----------------------------------------------------

%plotting: duration distribution, Adult
DurAnTab = DurationTab(contains(DurationTab.Speaker,'AN'),:); %get duration tab with CHNSP only
[X,X_Edges,Y_Cts,Y_cdf,Y_ccdf,Y_probs, ~] = GetVecsToPlot(DurAnTab.Duration,DurAnTab.InfAgeMnth,U_AgeMnths);
figure1 = figure('PaperType','<custom>','PaperSize',[20.5 9],'Color',[1 1 1]);

%duration frequency disribution
axes1 = axes('Parent',figure1,'Position',[0.101190476190477 0.150905285191 0.357804232804232 0.796282051282051]); hold(axes1,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_probs{i},'Color',AgeClrs(i,:),'LineWidth',1.5);
end
title('A');ylabel('Probability');xlabel('Duration, d (s)');
xlim(axes1,[0.6 50]); ylim(axes1,[-0.003 0.25]); hold(axes1,'off');
set(axes1,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorTick','on','XScale','log','XTick',[0.6 1 2 4 10 40],'XTickLabel',...
    {'0.6','1','2','4','10','40'},'YGrid','on','YLimitMethod','tight','ZLimitMethod','tight');
legend(axes1,{'3 months','6 months','9 months','18 months'},'Position',[0.273809523809524 0.846153846153846 0.181878306878307 0.0886970172684458],'NumColumns',2);

%duration ccdf
axes2 = axes('Parent',figure1,'Position',[0.60473244348244 0.150643642072214 0.357804232804232 0.797551020408163]); hold(axes2,'on');
for i = 1:numel(Y_probs)
    plot(X{i},Y_ccdf{i},'Color',AgeClrs(i,:),'LineWidth',1.5);
end
title('B');ylabel('P(D > d)'); xlabel('Duration, d (s)');
xlim(axes2,[0 40]); ylim(axes2,[2.2069292467e-05 1]); hold(axes2,'off');
set(axes2,'FontSize',24,'XGrid','on','XLimitMethod','tight','XMinorGrid','on','XTick',[0 10 20 30 40],'XTickLabel',{'0','10','20','30','40'},'YGrid',...
    'on','YLimitMethod','tight','YMinorTick','on','YScale','log','ZLimitMethod','tight');
annotation(figure1,'textbox',[0.00066137566137573 0.960538461538465 0.0281084656084656 0.0353218210361067],'String',{'Adult'});


%----------------------------------------------------------------------------------------------------------------------------------------------
%This function takes in the time series and a percentile value and bins the time series using a histogram. To do this, we first compute the histogram bin
% edges by partitioning data at the 5 percent level recursively (However, there is flexibility in choosing this, using the ReqPrctile input). That is, the 
% input TS is first partitioned at 5 percentile. Then the rest of the data (after removing the everything less than the 5 percentile value) is partitioned 
% again at the 5 percentile level, and so on, till the partitioning results in only 1 remaning data point. Each succesive 5 percentile value is stored. 
% The bin edges are given as follows: the first bin is min of data to 1st 5 percentile value; the second bin is from the first 5 percentile value to the second
% 5 percentile values, etc. The last bin is from the last 5 percentile value to max value in the data.
% 
% Inputs: Time series to be binned (TS) and the required percentile level for binning (ReqPrctile)
% Outputs: X_Edges: bin edges; Y_Cts: bin counts (raw counts); Y_cdf: y values for the cdf; Y_probs: y values for normalised probability;
%          SameBinEdgeFlag: flags true if there are a series of bin edges that are effectively the same (with allowed variations less than or equal to 10^-5) 
%          that are consecutive and effectively equal to the min value in the data.
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
    
    % Consider 'bins' specificed by the following bin edges: 0.6   0.6   0.6   0.6   0.8   1.2   1.2   1.2
    % Then, diff(X_Edges) will output this:                      0     0     0    0.2   0.4   0.4    0
    % NoDiffInds will pick out the following:                    1     2     3                       7
    % Diff_NoDiffInds will output this:                             0     0             4
    % That is, if there is only a single, consecutive series of bin edges that are the same, Diff_NoDiffInds will be a vector of 0s. That is all that the code
    % here is equipped to deal with because I am operating under the assumption that the only instance of thsi happening is with the 0.6 s infant duration minima.
    % If this is not the case, the error flag below will flag it and the code can be modified accordingly.
    if sum(abs(Diff_NoDiffInds)) ~= 0 %Take the sum of the diff of indices for bin edge values that are effectively the same (accounting for variations of the
        %order of ~10^-5 or less), after 1 has been subtracted from the diff of indices. The abs value makes it so that if there are any that are non-consecutive,
        % we will get a sum greater than 0. There shouldn't be any -ve values here, but this is a 'just in case' thing.
        error('Some bin edges that are effectively the same are not consecutive. That is, there are multiple and distinct events of bins with both bin edges being the same.')
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
% Inputs are the relevanr time series vector, eg. CHNSP IEI (IPTSVec), the corresponding Age vector (IpAgeVec), and the vector with the unique infant 
% ages (U_AgeMnths).
% Outputs are the X values (the bin centres; X), the bin edges (X_Edges), raw counts (Y_Cts), probability, cdf and ccdf values (Y_probs,Y_cdf, Y_ccdf).
% For an explanation of the output SameBinEdgeFlag, see function GetPtsToPlot, defined in this script.
function [X,X_Edges,Y_Cts,Y_cdf,Y_ccdf,Y_probs,SameBinEdgeFlag] = GetVecsToPlot(IpTSVec,IpAgeVec,U_AgeMnths)
    for i = 1:numel(U_AgeMnths) %go through unique infant age (months)
        TimeSeries = IpTSVec(IpAgeVec == U_AgeMnths(i)); %get the relevenat time series
        [X_Edges{i},Y_Cts{i},Y_cdf{i},Y_probs{i},SameBinEdgeFlag] = GetPtsToPlot(TimeSeries,5); %get bin edges, counts, and cdf values (using 5 percentile for partitioning)
        Y_ccdf_Temp = 1-Y_cdf{i}; %get ccdf
        Y_ccdf_Temp(Y_ccdf_Temp < 10^-6) = NaN; %truncate ccdf by removing values with probability < 10^-6
        Y_ccdf{i} = Y_ccdf_Temp;
        X{i} = 0.5*(X_Edges{i}(1:end-1)+X_Edges{i}(2:end)); %get bin mid points values
    end
end
%----------------------------------------------------------------------------------------------------------------------------------------------
%Below is a version of approaching this that still created binning artifacts. The number added (10, in this case) before logging changed binning as it was varied
% (understandably) and because of the nature of the data, I chose to do the binning as it is done now. Below, see the original rationale for the approach used below:
% 
%Duration and IEI are both skewed distributions with long tails as is evident from figures with range, mean, and median of durations in SI, as well as from previous 
% figures showing IEI distributions in [redacted paper for DAPR], from a subset of the current data. So, this is the strategy we use here, to get a good visualisation:
% First, the distributions are transformed by adding 10 to every value followed by log10. Then, the number of bins to use for histogram() is computed using the 
% Friedman diaconis rule on the log10( +10) transformed data. The bins for this histogram are retrieved and transformed back to fit the original data 
% (using -10 + 10^BinEdges). This gives log binning for the untransformed data without having too many bins in the 0-1 range, where roughly about 50% of IEI data falls
% for thr duration distribution. For IEI data, the median is around 7 for infants and about 3 for adults. At any rate, log transforming without adding 10 will make
% it so that the 0 to 1 range will be stretched in the log transformed data resulting in there being more bins than necessary (or optimal) to represent the 0 to 1
% range in the untransformed data. In showing the distributions, I do want to show the untransformed data without doing any fitting, so this was the best way to do 
% that without using more complex binning strategies (which is not the goal here--I simply want the reader to have a sense of what the data looks like).
% I choose to represent the data as a distribution of counts based on this process as well as a complementary cdf (1-cdf) to highlight how the tails of the
% distributions look like. In the counts representation, the tails are long but sparse for high values, resulting in a spiky distribtution that is somewhat difficult
% to make sense of easily. The complementary cdf provides a smoother visualisation in this case without having to resort to fitting procedures..
% %This function gets the distribution for a given time series, computed using histograms (the mid points of the histogram bins are the x points for the output). 
% % The input is the relevant time series, and the outputs are the x and y values.
% function [x,y, Edges] = getHistVals(TimeSeries)
%     TempFig = figure; %temporary figure to plot histogram
%     N = numel(TimeSeries); %get number of elements in TS
%     BinWidth = 2*iqr(TimeSeries)*(N^(-1/3)); %get bin width using Friedman Diaconis rule
%     NumBins = round(range(TimeSeries)/BinWidth); %get number of bins
% 
%     h = histogram(TimeSeries,'NumBins',NumBins); %get histogram
%     y = h.Values; %get values
%     x = (h.BinEdges(1:end-1)+h.BinEdges(2:end))/2; %get bin midpoints
%     Edges = h.BinEdges; %get bin edges
%     close(TempFig) %close the temp figure
% end
% 
% %----------------------------------------------------------------
% %This function gets the ccdf and frequency vectors to plot. Inputs are the relevanr time series vector, eg. CHNSP IEI (IPTSVec), 
% % the corresponding Age vector (IpAgeVec), and the vector with the unique infant ages (U_AgeMnths).
% function [X,Y_Cts,Y_ccdf] = GetVecsToPlot(IpTSVec,IpAgeVec,U_AgeMnths)
%     for i = 1:numel(U_AgeMnths)
%         TimeSeries = IpTSVec(IpAgeVec == U_AgeMnths(i)); %get the relevenat time series
%         LogTS = log10(TimeSeries+10); %add 10 and log by 10 (this is just to get the bins)
% 
%         [~,~, Edges] = getHistVals(LogTS); %get bin edges for transformed time series
%         TempFig = figure; % temp figure to plot histogarm
%         h = histogram(TimeSeries,-10+10.^Edges,'Normalization','cdf'); %get histogram for the actual times series but use the bins from 
%         % transforming bins from the original log( + 10) transform
%         Y_ccdf_Vec = 1-h.Values; %get Y values for complementary cdf
%         Y_ccdf_Vec(Y_ccdf_Vec < 10^-8) = NaN; %removing values that are too small
%         Y_ccdf{i} = Y_ccdf_Vec;
%         Y_Cts{i} = h.BinCounts; %get counts for distribution
%         X{i} = 0.5*(h.BinEdges(1:end-1)+h.BinEdges(2:end)); %get bin mid points values
%         close(TempFig); %close the temporary fig
%     end
% end