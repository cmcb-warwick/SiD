function job=sidFindCoords(job, reader, channel)
%SIDFINDCOORDS Find kinetochore coordinates
%
% SYNOPSIS: job=sidFindCoords(job, reader, channel)
%
% INPUT job: Struct containing tracking job setup options.
%
%       reader: BioFormats reader.
%
%       channel: Channel in which to find coords.
%
% OUTPUT job: as input but with updated values.
%
% Created by: J. W. Armond
% Modified by: C. A. Smith
% Copyright (c) 2017 C. A. Smith

% Set up data struct.
options = job.options;

is3D = job.metadata.is3D;
nDims = 2 + is3D;
filters = createFilters(nDims,job.dataStruct{channel}.dataProperties);

% Read image
img = sidReadImageStack(reader,job.metadata,channel,job.ROI.crop,0);
if ndims(img) > 3
  warning('Only single time point images can be run. Using time point 1.');
  img = img(:,:,:,1);
end
[imageSizeX,imageSizeY,imageSizeZ] = size(img);

% Initialize output structure
localMaxima = struct('cands',[],'candsAmp',[],'candsBg',[]);

% Find candidate spots.
switch options.detectMode
    case 'histcut'
        sidLog('Detecting particle candidates using unimodal histogram threshold');
        spots = histcutSpots(img,options,job.dataStruct{channel}.dataProperties);
        nSpots = size(spots,1);
    otherwise
        error('Detection mode not yet implemented into Sid: %s',options.detectMode);
end

% Round spots to nearest pixel and limit to image bounds.
if nSpots > 1
  spots = bsxfun(@min,bsxfun(@max,round(spots),1),[imageSizeX,imageSizeY,imageSizeZ]);
end
% Store the cands of the current image.
localMaxima.cands = spots;

% Get spot amplitudes and background.
if verLessThan('images','9.2')
  background = fastGauss3D(img,filters.backgroundP(1:3),filters.backgroundP(4:6));
else
  background = imgaussfilt3(img,filters.backgroundP(1:3),'FilterSize',filters.backgroundP(4:6));
end
if nSpots > 1
  spots1D = sub2ind(size(img),spots(:,1),spots(:,2),spots(:,3));
else
  spots1D = [];
end
localMaxima.candsAmp = img(spots1D);
localMaxima.candsBg = background(spots1D);

% Visualize candidates.
if options.debug.showMmfCands ~= 0
  showSpots(img,spots);
  title(['Local maxima cands n=' num2str(size(spots,1))]);
  drawnow;
  switch options.debug.showMmfCands
    case -1
      pause;
    case -2
      keyboard;
  end
end
sidLog('Number of particles detected: %.1f',nSpots);

if nSpots > 0
  % Refine spot candidates.
  switch options.refineMode
      case 'mmf'
          job = sidMixtureModel(job,img,localMaxima,channel);
      otherwise
          error('Refinement mode not yet incorporated into Sid: %s',options.refineMode);
  end
else
  % mark as failed, and give empty initCoord  
  dataStruct = job.dataStruct{channel};
  dataStruct.failed = 1;
  dataStruct.initCoord = struct('allCoord',[],'allCoordPix',[],'nSpots',0,'amp',[],'bg',[]);
  job.dataStruct{channel} = dataStruct;
end
  
end

