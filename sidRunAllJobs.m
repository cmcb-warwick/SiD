function sidRunAllJobs(jobsets)
% SIDRUNALLJOBS Runs all jobs across multiple jobsets.
%
% Accepts cell array of filenames or cell array of jobset structs.
%
% Created by: J. W. Armond
% Modified by: C. A. Smith
% Copyright (c) 2017 C. A. Smith

% Ensure input is cell array.
if ~iscell(jobsets)
  jobsets = {jobsets};
end

nJobsets = length(jobsets);
sidLog('Running %d jobs',nJobsets);
for i = 1:nJobsets
  jobset = jobsets{i};
  if ischar(jobset)
    jobset = sidLoadJobset(jobset);
  end
  sidLog('Running job %i: %s',i,jobset.filename);

  % Run it.
  sidRunJob(jobset);
end
