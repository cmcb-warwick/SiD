function job=sidDiagnostics(job,channel,elapsed)
% SIDDIAGNOSTICS Compute some basic tracking diagnostics
%
% Created by: J. W. Armond
% Modified by: C. A. Smith
% Copyright (c) 2016 C. A. Smith

ds = job.dataStruct{channel};

diag.elapsedTime = elapsed;

% Spots.
if channel==job.options.detectChan
diag.nSpots = ds.initCoord.nSpots;
end
diag.meanInt  = nanmean(ds.spotInt.intensity_mean);
diag.stdInt  = nanstd(ds.spotInt.intensity_mean);

% Store result.
ds.diagnostics = diag;
job.dataStruct{channel} = ds;
