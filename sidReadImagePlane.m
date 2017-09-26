function plane = sidReadImagePlane(imageReader,metadata,c,z,crop,normalize)
% SIDREADIMAGEPLANE Read a single image plane from a movie file.
%
%    PLANE = SIDREADIMAGEPLANE(IMAGEREADER,METADATA,C,Z,CROP,NORMALIZE) Read a
%    single image plane from an image file associated with open IMAGEREADER
%    and described by METADATA. Returns plane Z, in channel C (all one-based indexes).
%
%    CROP Optional, vector of [XMIN,YMIN,WIDTH,HEIGHT] for cropping.
%
%    NORMALIZE Optional, 0, 1 or -1. Normalize by maximum pixel value. Defaults
%    to 0, which converts datatype to double but doesn't normalize. If -1, no
%    normalization is performed and image is returned in original datatype.
%
% Copyright (c) 2013 Jonathan W. Armond

if nargin<5
  crop = [];
end

if nargin<6
  normalize = 0;
end

t = 1; %assume 1 time point
iPlane = imageReader.getIndex(z-1,c-1,t-1) + 1;
plane = bfGetPlane(imageReader,iPlane)';

% Crop if requested.
if ~isempty(crop)
  plane = imcrop(plane,crop);
end

% Convert to double.
if normalize >= 0
  if strcmp(metadata.dataType,'int8')
    % im2double doesn't support int8 for some reason.
    plane = int16(plane)*256;
  end
  plane = im2double(plane);
  if metadata.isFloatingPoint
    % Scale to [0,1] by dividing by 16-bit integer range.
    plane = plane / (2^16-1);
  end

  % Normalize by max pixel.
  if normalize == 1
    plane = plane / max(plane(:));
  end
end
