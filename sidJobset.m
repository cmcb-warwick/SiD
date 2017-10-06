function jobset=sidJobset(jobset)
% SIDJOBSET Create or upgrade a jobset.

if nargin<1
  jobset = sidDefaultOptions();
end

% Update from 1.03 to 1.1:
if jobset.jobsetVersion < 2
    jobset.options.detectMode = 'histcut';
    jobset.options.refineMode = 'mmf';
end