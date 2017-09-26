function sidRunJob(jobset,varargin)
% SIDRUNJOB Runs tracking analysis on JOBSET.
%
%    SIDRUNJOB(JOBSET,...) Runs tracking analysis on JOBSET. JOBSET should be
%    output from either SIDSETUPJOB or SIDLOADJOBSET. Additional options can
%    be supplied as string/value pairs.
%
%    Options (default in {}):-
%
%    tasks: {[1 2]} or a vector. Specify tasks to perform on jobs:
%                              1: finding spots
%                              2: intensity
%
%    existing: {0} or 1. Load existing jobs first.
%
%    exec: {'serial'}, 'parallel'. Execution mode.
%
%    subset: {[]} or vector of job numbers. Set to a subset of indices of movies
%    to analysis, instead of processing them all.
%
%    errorfail: {0} or 1. Crash out if error occurs if 1.
%
% Created by: J. W. Armond
% Modified by: C. A. Smith
% Copyright (c) 2017 C. A. Smith

% Check minimum MATLAB version.
% FIXME Check minimum toolbox versions also.
if verLessThan('matlab','7.14')
  error('Minimum required MATLAB version is 7.14 (R2012a)');
end

% Download BioFormats, if required.
sidDownloadBioFormats();

% Upgrade jobset options, if required.
if ~isfield(jobset,'jobsetVersion') || ...
    jobset.jobsetVersion < sidVersion(2)
  jobset = sidJobset(jobset);
end

nROIs = length(jobset.ROI);

% Default options.
options.subset = 1:nROIs;
options.exec = 'serial';
options.errorfail = 0;
options.tasks = [1 2];
options.existing = 0;
% Get user options.
options = processOptions(options, varargin{:});

% Check options.
if ~all(ismember(options.subset,1:nROIs))
  error('Subset values must be in range 1 to %d',nROIs);
end

% If using matlabpool for parallel computation, report workers.
[~,name] = fileparts(jobset.filename);
switch options.exec
  case 'batch'
    sidLog(['Running ' name ' in parallel']);
  case 'serial'
    sidLog(['Running ' name ' serially']);
end

% Copy out job info for each movie.
jobs = cell(nROIs,1);
for i=1:nROIs
  if options.existing
    jobs{i} = sidLoadJob(jobset,i);
    % Copy over any new options.
    jobs{i}.options = jobset.options;
  else
    jobs{i} = jobset;
    jobs{i}.ROI = jobset.ROI(i);
    jobs{i}.nROIs = nROIs;
    if isfield(jobs{i},'metadata')
      jobs{i}.metadata = jobset.metadata{i};
    end
    jobs{i}.index = i;
  end
  % Update versions, may be different to jobset creator.
  jobs{i}.version = sidVersion();
  jobs{i}.matlabVersion = version;
  % Record host.
  if ispc
    [~,jobs{i}.host] = system('echo %COMPUTERNAME%');
  else
    [~,jobs{i}.host] = system('hostname');
  end
end

exceptions = [];
for i = options.subset
  switch options.exec
    case 'parallel'
      sidLog('Submitting tracking job %d', i);
      batchJob{i} = batch(@sidProcessImage, 1, {jobs{i},options.tasks});
    case 'serial'
      try
        sidLog('Tracking job %i of %i', i, nROIs);
        sidProcessImage(jobs{i},options.tasks);
      catch me
        sidLog('Error in job %d: %s',i,me.identifier);
        ex.me = me;
        ex.idx = i;
        exceptions = [exceptions ex];
        if options.errorfail
          disp(getReport(me));
          throw(me);
        end
      end
  end
end


if ~isempty(exceptions)
  disp('Errors occured:')
end
for i = 1:length(exceptions)
  ex = exceptions(i);
  fprintf('In job %d, error %s:\n',ex.idx,ex.me.identifier);
  disp(getReport(ex.me));
end

if strcmp(options.exec,'batch')
  % Wait for parallel tracking jobs.
  for i = options.subset
    sidLog('Waiting for %d tracking jobs to complete', length(options.subset)-i+1);
    b = batchJob{i};
    wait(b);
    diary(b);
    delete(b);
  end
end

sidLog('Spot detection complete');

% Dump jobset diagnostics
% [pathstr,name,ext] = fileparts(jobset.filename);
% diagfile = ['diags_' name];
% if isfield(jobset,'variantName')
%   diagfile = [diagfile '_' jobset.variantName];
% end
% diagfile = fullfile(pathstr,[diagfile '.txt']);
% fid = fopen(diagfile,'wt');
% C = onCleanup(@() fclose(fid));
% for c = 1:length(jobset.options.coordMode)
%   if ~strcmp(jobset.options.coordMode{c}, 'none')
%     sidJobsetDiagnostics(jobset,c,0,fid);
%   end
% end
