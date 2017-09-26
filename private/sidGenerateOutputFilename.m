function outputName=sidGenerateOutputFilename(job)
% SIDGENERATEOUTPUTFILENAME Generate filename for output mat based on jobset name

[~,jobsetName] = fileparts(job.filename);
[moviePath,movieName] = fileparts(job.ROI.movie);


if isfield(job,'jobsetVersion')
  % Add index near front of filename to improve filesystem sorting.
  fileName = ['siddetection' num2str(job.index,'%03d') '-' jobsetName '-' movieName];
else
  fileName = ['siddetection-' jobsetName '-' movieName];
end
if isfield(job,'variantName')
  % Add variant to name for testing purposes.
  fileName = [fileName '-' job.variantName];
end
fileName = [fileName '.mat'];

% Generate output name including jobset name.
outputName = fullfile(job.movieDirectory, moviePath, fileName);
