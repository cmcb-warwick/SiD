function job=sidLoadJob(jobsetorname, index)
% SIDLOADJOB Load tracking data from job
%
%    JOB = SIDLOADJOB(JOBSET,INDEX) Load tracking data from job number INDEX
%    from JOBSET.
%
%    JOB = SIDLOADJOB(FILENAME) Load tracking data by job FILENAME.
%
% Copyright (c) Jonathan Armond 2016

if ischar(jobsetorname)
  outputName = jobsetorname;
else
  jobset = jobsetorname;
  % Generate output name.
  job = jobset;
  job.ROI = jobset.ROI(index);
  job.index = index;
  outputName = sidGenerateOutputFilename(job);
end

% Load file.
job = load(outputName);

% Update paths to match jobset. Data may have moved.
if ischar(jobsetorname)
  % Use directory of job file.
  pathstr = fileparts(jobsetorname);
  job.movieDirectory = pathstr;
  job.filename = jobsetorname;
else
  job.movieDirectory = jobset.movieDirectory;
  job.filename = jobset.filename;
end
job.output = outputName;
