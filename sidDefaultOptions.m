function job=sidDefaultOptions()
% SIDDEFAULTOPTIONS Populate default options structure.
%
%    JOB = SIDDEFAULTOPTIONS() Create job struct populated with defaul
%    options.
%
% Copyright (c) 2017 C. A. Smith

job.sid = 1;
job.software = ['Sid ' sidVersion()];
job.jobsetVersion = sidVersion(2);
job.matlabVersion = version;

job.movieDirectory = [];
job.movieFiles = [];
job.ROI = [];

% Detection and refinement modes.
opts.detectMode = 'histcut';
opts.refineMode = 'mmf';

% Channel options.
opts.detectChan = 1;
opts.measureChans = [1 0 0 0];

% Spot detection options.
opts.minSpots = 20;
opts.maxSpots = 150;

% Gaussian mixture-model spot finding options.
opts.mmfSensitivity = 0.05; % detection sensitivity: amplitude t-test cutoff.
opts.mmfMaxTime = 300; % Maximum per-frame time (s) to attempt mixture model fit
                    % before giving up.  Use zero to disable.

% Intensity measurement options.
opts.maskRadius = 0.3; % um
opts.gaussFilterSpots = 0; % whether or not to Gauss-filter before intensity measurement.

% Output file grouping status.
opts.groupOutput = 0; % whether or not to group siddetection files into a separate folder.

% Debug options.
debug.showMmfClusters = 0; % visualize clustering from overlapping PSFs, -1
                           % to pause, -2 to debug.
debug.showMmfCands = 0; % visualize centroid candidates, -1 to pause
debug.showMmfFinal = 0; % visualize final MMF spots, -1 to pause
debug.showMmfPvals = 0; % histogram of mixture-model p-values
debug.mmfVerbose = 0; % display detailed progress of mixture-model fitting.
debug.showIntensityMasks = 0;
debug.showCentroidFinal = 0; % visualize centroid final spots.
debug.asserts = 0; % check things that shouldn't go wrong
debug.disableSave = 0; % don't save job at each step
opts.debug = debug;

job.options = opts;
