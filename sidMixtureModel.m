function job = sidMixtureModel(job,image,localMaxima,channel)
% Refine spots in 3D using Gaussian mixture model fits
%
% Created by: Jacques Boisvert and K. Jaqaman
% Modified by: J. W. Armond and C. A. Smith
% Copyright (c) 2017 C. A. Smith

%% Input + initialization

dataStruct = job.dataStruct{channel};
opts = job.options;
dataStruct.failed = 0;

% calculate alphaA based on pixel size
% (standards: 0.05 at 138.1nm; 0.5 at 69.4nm)
pixelSize = job.metadata.pixelSize;
opts.mmfSensitivity = opts.mmfSensitivity.*(opts.mmfSensitivity + (0.1381-pixelSize(1))*8)/0.05;

% get image information
is3D = job.metadata.is3D;
ndims = 2 + is3D;
filterPrm = dataStruct.dataProperties.FILTERPRM;

% get psf sigma from filterPrm
if is3D
  psfSigma = [filterPrm(1) filterPrm(3)];
else
  psfSigma = filterPrm(1);
end

%initialize initCoord
initCoord = struct('allCoord',[],'allCoordPix',[],'nSpots',0,'amp',[],'bg',[]);

sidLog('Refining particles using mixture-model fitting');
prog = sidProgress(0);

% Get frame.
imageRaw = image;
% Get candidate maxima, and append spotIDs to the end
cands = localMaxima.cands;

% Start clock - used later to ensure it doesn't take too long.
startTime = clock;

% Run mixture model fitting.
[coordList,ampList,bgList,rejects] = mixtureModelFit(cands,imageRaw,psfSigma,opts);
  
elapsedTime = etime(clock,startTime);
if opts.mmfMaxTime > 0 && elapsedTime > opts.mmfMaxTime
  warning('Mixture-model fitting taking excessive time (%g min per frame). Aborting.',elapsedTime/60);
  dataStruct.failed = 1;
  return
end
% Process the results.
nSpots = size(coordList,1);
if ~is3D
  coordList = [coordList(:,1:2) zeros(nSpots,1) coordList(:,3:4) zeros(nSpots,1)];
end

% Visualize final result.
if opts.debug.showMmfFinal ~= 0
  % If 3D image, max project.
  img = max(imageRaw,[],3);
  figure(1);
  imshow(img,[]);

  % Plot image and overlay spots.
  hold on;
  plot(cands(:,2),cands(:,1),'b+');
  if ~isempty(rejects.amp)
    plot(rejects.amp(:,1),rejects.amp(:,2),'gx');
  end
  if ~isempty(rejects.dist)
    plot(rejects.dist(:,1),rejects.dist(:,2),'yx');
  end
  if ~isempty(coordList)
    plot(coordList(:,1),coordList(:,2),'rx');
  end

  title('MMF fitted particles (r), cands (b), amp rej (g), dist rej (y)');
  hold off;
  drawnow;
  switch opts.debug.showMmfFinal
    case -1
      pause;
    case -2
      keyboard;
  end
end

if opts.debug.showMmfPvals ~= 0
  figure(2);
  subplot(2,1,1);
  if ~isempty(rejects.amp)
    histogram(rejects.amp(:,ndims+1));
  end
  title('Amplitude reject p-vals');
  subplot(2,1,2);
  if ~isempty(rejects.dist)
    histogram(rejects.dist(:,ndims));
  end
  title('Distance reject p-vals');
  drawnow;
  switch opts.debug.showMmfPvals
    case -1
      pause;
    case -2
      keyboard;
  end
end
  
%save results
initCoord.nSpots = nSpots;
initCoord.allCoordPix = coordList;
initCoord.amp = ampList;
initCoord.bg = bgList;
%check whether frame is empty
if nSpots == 0
  initCoord.allCoord = initCoord.allCoordPix;
else
  % calc real space coordinates and correct for chromatic shift
  initCoord.allCoord = initCoord.allCoordPix .* repmat(pixelSize,initCoord.nSpots,2);
end

%display progress
sidProgress(1,prog);

% save results
initCoord.localMaxima = localMaxima;
dataStruct.dataProperties.psfSigma = psfSigma;
dataStruct.initCoord = initCoord;
dataStruct.failed = dataStruct.failed || nSpots==0;

job.dataStruct{channel} = dataStruct;
