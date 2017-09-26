function jobset=sidJobset(jobset)
% SIDJOBSET Create or upgrade a jobset.

if nargin<1
  jobset = sidDefaultOptions();
end