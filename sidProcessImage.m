function job = sidProcessImage(job,tasks)
% SIDPROCESSIMAGE Locates spots for a single image.
%
%    JOB = SIDPROCESSIMAGE(JOB) Detects and refines spot positions for a
%    single image described by JOB. Populates cell array field .dataStruct
%    with results for the detection channel.
%
% Created by: J. W. Armond
% Modified by: C. A. Smith
% Copyright (c) 2017 C. A. Smith

tstart = tic;

if nargin<2 || isempty(tasks)
  tasks = [1 2];
end
% 1: finding spots
% 2: intensity

% Get movieDirectory and movie
movieDir = job.movieDirectory;
movie = job.ROI.movie;

% Open movie and read metadata.
if isfield(job,'metadata')
  [job.metadata, reader] = sidOpenMovie(fullfile(movieDir,movie),'valid',job.metadata);
else
  [job.metadata, reader] = sidOpenMovie(fullfile(movieDir,movie),'init');
end
job = sidSaveJob(job);

opts = job.options;
nChannels = min(job.metadata.nChannels,4);

% Check which channel to analyze.
sdChan = opts.detectChan;
intChans = find(opts.measureChans);
if isempty(sdChan) || isempty(intChans)
  error('No channels selected for analysis (movie has %d)',nChannels);
end

% Make dataStruct and update any changed options.
ds = sidMakeDatastruct(job,sdChan);
job.dataStruct{sdChan}.dataProperties = ds.dataProperties;

if ismember(1,tasks)
  % Find 3D spot coordinates per frame.
  sidLog('Finding particle coordinates in channel %d',sdChan);
  job = sidFindCoords(job, reader, sdChan);
  job = sidSaveJob(job);
  % Give up if spot finding failed.
  if isfield(job.dataStruct{sdChan},'failed') && job.dataStruct{sdChan}.failed
    warning('Giving up on job.');
    return
  end
end

if ismember(2,tasks)
  % Read spot intensity.
  for c = intChans
    sidLog('Measuring spot intensity in channel %d',c);
    job = sidMeasureIntensity(job, reader, c);
  end
  job = sidSaveJob(job);
end

% Gather diagnostics.
elapsed = toc(tstart);
sidLog('Gathering diagnostics');
fprintf('Elapsed compute time: %s\n',timeString(elapsed));
for c = intChans
  job = sidDiagnostics(job,c,elapsed);
  fprintf('-------------------------\n');
  fprintf('Diagnostics for channel %d\n', c);
  sidPrintDiagnostics(job.dataStruct{c});
end
fprintf('-------------------------\n');
fprintf('\n')
job = sidSaveJob(job);

reader.close();
clear reader;

