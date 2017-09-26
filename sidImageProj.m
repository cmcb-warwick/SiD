function [figH,rgbImg,z]=sidImageProj(imageFileName,zPlane,roi)
% SIDIMAGEPROJ Presents image projection in Z
%
%  SYNOPSIS sidImageProj(imageFileName)
%
%  INPUT imageFileName: Filename of image to crop.
%        zPlane: Show single z-plane (optional).
%
% Copyright (c) 2012 Jonathan W. Armond

if nargin<2
  zPlane=[];
end
if nargin<3
  roi=[];
end

% Open movie.
[metadata,reader] = sidOpenMovie(imageFileName,'ROI');

% Loop to create max projections.
maxMergeChannels = 3;
imgSz = [metadata.frameSize(1:2), 3];

centreSz = 0.5; % Take central percentage for locating threshold.
border = (1-centreSz)/2;
cx(1) = round(imgSz(1)*border);
cx(2) = round(cx(1) + imgSz(1)*centreSz);
cy(1) = round(imgSz(2)*border);
cy(2) = round(cy(1) + imgSz(2)*centreSz);

rgbImg = zeros(imgSz);
mapChan = [2 1 3];
for c=1:min([maxMergeChannels, metadata.nChannels])
  if isempty(zPlane)
    img = sidReadImageStack(reader, metadata, c);
  else
    img = sidReadImagePlane(reader, metadata, c, zPlane);
  end
  z = size(img,3);
  % Max projection of image.
  maxProj = max(img,[],3);

  % Merge into RGB image.
  centreImg = maxProj(cx(1):cx(2),cy(1):cy(2),:);
  lb = splitModes(centreImg(centreImg>0));
  if isempty(lb)
    % Can't identify background. Use sensible default.
    lb = 0.75;
  end
  slim = stretchlim(centreImg,[lb 1]);
  rgbImg(:,:,mapChan(c)) = imadjust(maxProj,slim,[]);
end

figH = figure;
imshow(rgbImg);
set(figH,'Units','characters','Position',[100 35 100 50]);
movegui(figH,'center');

if ~isempty(roi)
  rectangle('Position',roi,'LineWidth',2,'EdgeColor','y');
end

