function sidSaveJobset(jobset)
% SIDSAVEJOBSET Save jobset in mat-file
%
% Copyright (c) 2013 Jonathan W. Armond

save(jobset.filename,'-struct','jobset','-v7.3');