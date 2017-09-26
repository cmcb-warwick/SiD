function varargout = intensityMeasurements(imageStructs,varargin)
% Produce an analysis structure pertaining to intensity measurements.
%
%

% default vs user-defined options
opts.analysisChans = [1 2];
opts.cellFilter = 1;
opts.controlChan = 2;
opts.measure = 'mean'; % mean, max, median, min
opts = processOptions(opts,varargin{:});

% process input
if nargin<1 || isempty(imageStructs)
    error('Please provide a movie structure.')
elseif ~iscell(imageStructs{1})
    imageStructs = {imageStructs};
end
if length(opts.controlChan)>1
    opts.controlChan = opts.controlChan(1);
    sidLog('Cannot have multiple control channels. Using channel %i as control.',opts.controlChan);
end
if ismember(opts.controlChan,opts.analysisChans)
    % remove control chan from list of analysis channels
    opts.channels = opts.analysisChans;
    opts.analysisChans = setdiff(opts.analysisChans,opts.controlChan);
else
    opts.channels = sort([opts.controlChan opts.analysisChans]);
end
opts.analysisChans = opts.analysisChans(:)';

% get some basic information
nExpts = length(imageStructs);
norms = struct('cellwise',[],'spotwise',[]);
analysis = struct('raw',[],...
                  'norm',norms,...
                  'bg',[],...
                  'stats',[]);

%% Collect data from movies

% make collection structures
allSpotInts = [];
allBg = [];
allNorms = [];
for iExpt = 1:nExpts
    
    % get this movieStruct
    thisMS = imageStructs{iExpt};
    nImgs = length(thisMS);
    
    % set up progress bar per experiment
    sidLog('Processing expt %i:',iExpt)
    prog = sidProgress(0);
    
    for iImg = 1:nImgs
        
        % get this movie
        thisImg = thisMS{iImg};
        
        % check whether there is any data in the given channels
        if ~isfield(thisImg,'dataStruct')
            sidLog('No dataStruct detected: mov %i', iImg);
            continue
        elseif length(thisImg.dataStruct) < max(opts.channels)
            sidLog('Data structure not present for all analysis channels: mov %i', iImg);
            continue
        elseif any(~ismember(opts.channels,find(thisImg.options.measureChans == 1)))
            sidLog('Not all analysis channels were measured for intensities: mov %i', iImg);
            continue
        elseif ~isfield(thisImg.dataStruct{opts.controlChan},'spotInt')
            sidLog('No spots found from which to measure intensities: mov %i', iImg);
            continue
        elseif isfield(thisImg,'keep') && ~thisImg.keep && opts.cellFilter
            sidLog('Image ignored due to manual cell filtering: mov %i', iImg);
            continue
        end
        
        % set up collection arrays
        nSpots = length(thisImg.dataStruct{opts.controlChan}.spotInt.intensity_mean);
        spotInts = nan(nSpots,4);
        bg = nan(1,4);
        
        % loop over channels
        for iChan = opts.channels
            
            % get this channel's spot intensities
            thisSpotInt = thisImg.dataStruct{iChan}.spotInt;
            thisCellInt = thisImg.dataStruct{iChan}.cellInt;
            % get background intensities
            bg(1,iChan) = thisCellInt.back;
            % get the desired measure of intensity
            switch opts.measure
                case 'mean'
                    spotInts(:,iChan) = thisSpotInt.intensity_mean(:);
                case 'max'
                    spotInts(:,iChan) = thisSpotInt.intensity_max(:);
                case 'median'
                    spotInts(:,iChan) = thisSpotInt.intensity_median(:);
                case 'min'
                    spotInts(:,iChan) = thisSpotInt.intensity_min(:);
            end
        end
        
        % correct spotInts for background
        bg = repmat(bg,nSpots,1);
        spotInts = spotInts - bg;
        
        % store cell's data
        allSpotInts = [allSpotInts; spotInts];
        allBg = [allBg; bg];
        % calculate cell-normalised data
        meanCtrl = nanmean(spotInts(:,opts.controlChan));
        allNorms = [allNorms; spotInts./meanCtrl];
        
        % update progress
        prog = sidProgress(iImg/nImgs,prog);
        
    end
    
end

indNorms = allSpotInts./repmat(allSpotInts(:,opts.controlChan),1,4);    
    
%% Save and output data

% store data in analysis structure
analysis.channels = sort(opts.channels);
analysis.raw = allSpotInts;
analysis.bg = allBg;
analysis.norm.cellwise = allNorms;
analysis.norm.spotwise = indNorms;

% update stats - make a table of the statistics


% give results to output arguments
if nargout == 1
    varargout{1} = analysis;
end


end