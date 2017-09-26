function compareBoxWhiskers(data,varargin)
%COMPAREBOXWHISKERS Produces overlaid box-and-whisker plots of up to 5
% distributions.
%
%    COMPAREBOXWHISKERS(DATA,...) For n distributions of DATA in cell form
%    {nx1}, box-and-whisker plots are plotted. Outliers can be allocated
%    as points failing a t-test with a defined probability.
%
%    Example of use:-
%    
%    compareBoxWhiskers({inputData1,inputData2},'showOutliers',1,'outlierP',0.01)
%        will plot two box-and-whisker plots with outliers shown, defined
%        as data that fail t-tests with probability of 99%.
%
%    Options, defaults in {}:-
%
%    legend: {'Expt 1', ...} or similar. Titles for each experiment, as
%             will be shown on the x-axis beneath each distribution.
%
%    outlierP: {0.05} or number in [0 1]. The probability (alpha) below
%             which to reject data from the main distribution, instead
%             plotting as outliers.
%
%    showOutliers: {0} or 1. Whether or not to plot outliers.
%    
%    title: {''} or a string. Title of the plot.
%
%    withinFig: {0} or 1. Defines whether or not to plot the 1D scatter
%             within the current figure environment.
%
%    yLabel: {'measurement (units)'} or similar. Label for the y-axis.
%   
% Copyright (c) 2017 C.A.Smith

% Set defaults
opts.legend = [];
opts.outlierP = 0.05;
opts.showOutliers = 0;
opts.title = '';
opts.withinFig = 0;
opts.yLabel = 'measurement (units)';

% Process options
opts = processOptions(opts, varargin{:});
CC = [ 0 , 0 , 1;
       1 , 0 , 0;
      0.5, 1 , 0;
      0.5, 0 , 1;
       0 , 0 , 0];
nCols = size(CC,1);
       

%% Data handling

% Process data
if iscell(data)
    nExpts = length(data);
    for iExpt = 1:nExpts
        % Remove any unwanted data
        data{iExpt} = data{iExpt}(~isnan(data{iExpt}));
        % Ensure all datasets are column vectors
        data{iExpt} = data{iExpt}(:);
        emptyData(iExpt) = isempty(data{iExpt});
    end
    if sum(emptyData) == nExpts
        error('Empty dataset provided.')
    end
else
    % Ensure data is in a cell in column vector form (if it isn't empty)
    % Remove any NaNs in the process
    if isempty(data)
        error('Empty dataset provided.')
    else
        % Remove any unwanted data
        data = data(~isnan(data));
        % Ensure all datasets are column vectors
        data = data(:);
        data = {data};
        nExpts=1;
    end
end

% Check have enough colours for the number of experiments
if nExpts > nCols
   CC = repmat(CC,ceil(nExpts/nCols),1); 
end

% Ensure that there are legends for each experiment
if isempty(opts.legend)
  for iExpt = 1:nExpts
    legends{iExpt} = ['Expt ' num2str(iExpt)];
  end
else
  legends = opts.legend;
end
  

%% Plotting data

if ~opts.withinFig
    figure()
    clf
end
hold on

for iExpt = 1:nExpts
  
  xData = iExpt;
  nPoints = length(data{iExpt});
  legends{iExpt} = sprintf('%s (n=%i)',legends{iExpt},nPoints);
  
  % sort the data
  thisData = sort(data{iExpt});
  % get basic statistics
%   data_mean = nanmean(thisData);
  data_median = nanmedian(thisData);
  data_25pc = prctile(thisData,25);
  data_75pc = prctile(thisData,75);
  
  % find which datapoints are considered upper outliers
  testData = thisData(thisData>data_75pc);
  nTests = length(testData);
  if nTests > 0
    c=0; stop=0;
    while ~stop && c < nTests
      c=c+1;
      stop = ttest2(thisData,testData(c),'alpha',opts.outlierP);
    end
    if stop
      lastInlier = testData(c-1);
      upperOutliers = testData(c:end);
    else
      lastInlier = testData(nTests);
      upperOutliers = [];
    end
  else
    lastInlier = thisData(end);
    upperOutliers = [];
  end
  
  % find which datapoints are considered lower outliers
  testData = thisData(thisData<data_25pc);
  nTests = length(testData);
  if nTests > 0
      c=nTests+1; stop=0;
      while ~stop && c > 1
        c=c-1;
        stop = ttest2(thisData,testData(c),'alpha',opts.outlierP);
      end
      if stop
        firstInlier = testData(c+1);
        lowerOutliers = testData(1:c);
      else
        firstInlier = testData(1);
        lowerOutliers = [];
      end
  else
    firstInlier = thisData(1);
    lowerOutliers = [];
  end
  
  % update data to remove outliers
  thisData = thisData(thisData>=firstInlier & thisData<=lastInlier);
  data_mean = nanmean(thisData);
      
  rectangle('Position',[xData-0.25 data_25pc 0.5 data_75pc-data_25pc])
  % plot the medians and means
  line([xData-0.25 xData+0.25],[data_median data_median],'Color',CC(iExpt,:))
  scatter(xData,data_mean,'+','MarkerEdgeColor',CC(iExpt,:))
  % draw whiskers
  line([xData xData],[data_75pc  lastInlier],'Color','k')  
  line([xData xData],[data_25pc firstInlier],'Color','k')
  
  % plot outliers
  if opts.showOutliers
    scatter(ones(length(lowerOutliers),1)*xData, lowerOutliers,'x','MarkerEdgeColor','k')
    scatter(ones(length(upperOutliers),1)*xData, upperOutliers,'x','MarkerEdgeColor','k')
  else
    line([xData-0.05 xData+0.05],[firstInlier firstInlier],'Color','k')
    line([xData-0.05 xData+0.05],[lastInlier lastInlier],'Color','k')
  end
  
end

%% Aesthetics

% Adjust y-axis limits
xlim([0 nExpts+1])
    
% Apply legend, title and axis labels
set(gca,'FontSize',20)

title(opts.title, 'FontSize', 20)
ylabel(opts.yLabel)
set(gca,'XTick',1:nExpts)
set(gca,'XTickLabel',legends)

end
