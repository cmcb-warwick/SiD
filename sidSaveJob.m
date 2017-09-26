function job = sidSaveJob(job)
% SIDSAVEJOB Saves job struct with standardized name
%
%    JOB = SIDSAVEJOB(JOB) Saves job struct as mat-file with name based on movie
%    filename: siddetection_jobsetFilename_movieFilename.mat
%
% Created by: J. W. Armond
% Modified by: C. A. Smith
% Copyright (c) 2017 Chris A. Smith

% Certain modes prohibit saving of output.
if (isfield(job.options.debug,'disableSave') && job.options.debug.disableSave) || ...
    (isfield(job,'disableSave') && job.disableSave)
  return;
end

% Generate output name.
outputName = sidGenerateOutputFilename(job);

if ~isfield(job,'output')
    % Generate output name.
    job.output = outputName;
end

% Save mat.
save(job.output, '-struct', 'job', '-v7.3');
