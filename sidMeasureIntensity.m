function job=sidMeasureIntensity(job, reader, channel)
% SIDMEASUREINTENSITY Measure intensity local to kinetochores
%
% Intensity values are NOT corrected for background. Use the cellInt
% structure to correct for this during analysis.
%

%% Preparation: produce structures

opts = job.options;
md = job.metadata;

% check if this channel contains coordinate or track information, or neither
sdChan = opts.detectChan;
initCoord = job.dataStruct{sdChan}.initCoord;
nSpots = initCoord.nSpots;

% predesignate intensity structure
intStruct = struct(...
    'intensity_mean',nan(nSpots,1),...
    'intensity_median',nan(nSpots,1),...
    'intensity_min',nan(nSpots,1),...
    'intensity_max',nan(nSpots,1),...
    'intensity_ratio',nan(nSpots,1),...
    'maskCoord',nan(nSpots,3),...
    'maxCoord',nan(nSpots,3),...
    'distToMax',nan(nSpots,1));

% Gaussian filter
hgauss = fspecial('gauss');


%% Create mask
r = round(opts.maskRadius / md.pixelSize(1));
se = strel('disk', r, 0);
mask = double(se.getnhood());
mask(mask == 0) = nan;

%% Get intensities

prog = sidProgress(0);
stack = sidReadImageStack(reader, md, channel, job.ROI.crop, 0);
if opts.gaussFilterSpots
  % Gaussian filter each z-plane.
  for z=1:size(stack,3)
    stack(:,:,z) = imfilter(stack(:,:,z), hgauss, 'replicate');
  end
end

% Take overall fluorescence estimate.
back = mean(stack(:));

% Estimate background and signal.
[backMode,sigVal,imgHist] = estBackgroundAndSignal(stack);
intensityDistF(:) = imgHist(:,2);
intensityDistX(:) = imgHist(:,1);

% Estimate background as difference between signal mode and background mode.
backDiff = sigVal - backMode;
    
for iSpot=1:nSpots
  
  if iSpot>0 && iSpot<size(initCoord.allCoordPix,1)
        
    % Read off intensity in radius r around spot.
    pixCoords = initCoord.allCoordPix(iSpot,1:3);

    if ~any(isnan(pixCoords))
      
      % Use spot coordinates as guide for mask.
      maskCoords = pixCoords;

      % Extract intensity.
      x = max(1,round(maskCoords(1)));
      y = max(1,round(maskCoords(2)));
      z = max(1,round(maskCoords(3)));
      if z > size(stack,3)
        warning('Spot outside frame boundaries');
        continue
      end
      if size(stack,3)>1
        imgPlane = stack(:,:,z);
      else
        imgPlane = stack;
      end
      [my,mx] = size(imgPlane);
      % If too close to edge, skip.
      if x <= r || y <= r || x >= mx-r || y >= my-r
        continue
      end

      % Coordinates are in image system, so plot(x,y) should draw the
      % spots in the correct place over the image. However, the image
      % matrix is indexed by (row,col) => (y,x).
      maskImg = mask .* imgPlane(y-r:y+r, x-r:x+r);
      nonNanPix = maskImg(~isnan(maskImg));
      intStruct.intensity_mean(iSpot,:) = mean(nonNanPix);
      intStruct.intensity_median(iSpot,:) = median(nonNanPix);
      intStruct.intensity_max(iSpot,:) = max(nonNanPix);
      intStruct.intensity_min(iSpot,:) = min(nonNanPix);
      intStruct.intensity_ratio(iSpot,:) = ...
          intStruct.intensity_max(iSpot,:)/intStruct.intensity_min(iSpot,:);
      intStruct.maskCoord(iSpot,:) = maskCoords;
      %[maxX,maxY] = ind2sub(size(maskImg),maxIdx);
      [~,maxIdx] = max(maskImg(:));
      [maxY,maxX] = ind2sub(size(maskImg),maxIdx);
      intStruct.maxCoord(iSpot,:) = [maxX+x-r-1,maxY+y-r-1,z];

      % Calculate distance between spot and max point.
      vector = pixCoords-intStruct.maxCoord(iSpot,:);
      intStruct.distToMax(iSpot,:) = norm(vector(1:2),2)*md.pixelSize(1);
    end
    
  end
  
  % Report progress.
  prog = sidProgress(iSpot/nSpots, prog);
  
end

% record background intensity
cellInt.back = back;
cellInt.backMode = backMode;
cellInt.backDiff = backDiff;
cellInt.maskPixelRadius = r;
cellInt.intensityDistF = intensityDistF;
cellInt.intensityDistX = intensityDistX;

% return data
job.dataStruct{channel}.cellInt = cellInt;
job.dataStruct{channel}.spotInt = intStruct;

end
